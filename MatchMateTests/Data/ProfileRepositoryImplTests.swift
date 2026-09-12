//
//  ProfileRepositoryImplTests.swift
//  MatchMateTests
//

import XCTest
@testable import MatchMate

final class ProfileRepositoryImplTests: XCTestCase {

    private let config = APIConfig(
        baseURL: URL(string: "https://test.example/api/")!,
        seed: "test",
        resultsPerPage: 3
    )

    private func makeRepo(
        client: MockHTTPClient = MockHTTPClient(),
        store: MockProfileStore = MockProfileStore(),
        monitor: MockNetworkMonitor = MockNetworkMonitor()
    ) -> ProfileRepositoryImpl {
        ProfileRepositoryImpl(
            remote: RandomUserRemoteDataSource(client: client, config: config),
            store: store,
            monitor: monitor,
            config: config
        )
    }

    // MARK: Bootstrap

    func test_bootstrap_emptyCacheOnline_fetchesPageOne() async throws {
        let client = MockHTTPClient()
        client.responsesByPage["1"] = .success(RandomUserJSON.page(count: 3))
        let store = MockProfileStore()

        try await makeRepo(client: client, store: store).bootstrap()

        let stored = try await store.fetchAll()
        XCTAssertEqual(stored.map(\.sortIndex), [0, 1, 2])
    }

    func test_bootstrap_emptyCacheOffline_throwsOfflineNoCache() async {
        let client = MockHTTPClient()
        client.defaultResult = .failure(.connectivity)
        let repo = makeRepo(client: client, monitor: MockNetworkMonitor(connected: false))

        await assertThrowsAsync(try await repo.bootstrap()) {
            XCTAssertEqual($0 as? AppError, .offlineNoCache)
        }
    }

    func test_bootstrap_withCache_emitsCacheBeforeAnyNetwork() async throws {
        let cached = Profile.page(1, perPage: 3, status: .accepted)
        let repo = makeRepo(
            store: MockProfileStore(seed: cached),
            monitor: MockNetworkMonitor(connected: false) // no background refresh
        )

        try await repo.bootstrap()

        var iterator = repo.profiles().makeAsyncIterator()
        let emitted = await iterator.next()
        XCTAssertEqual(emitted?.map(\.id), cached.map(\.id))
        XCTAssertEqual(emitted?.allSatisfy { $0.status == .accepted }, true)
    }

    // MARK: Pagination

    func test_loadNextPage_mergesAndAssignsSortIndex() async throws {
        let client = MockHTTPClient()
        client.responsesByPage["1"] = .success(RandomUserJSON.page(count: 3, idPrefix: "p1"))
        client.responsesByPage["2"] = .success(RandomUserJSON.page(count: 3, idPrefix: "p2"))
        let store = MockProfileStore()
        let repo = makeRepo(client: client, store: store)

        try await repo.bootstrap()
        try await repo.loadNextPage()

        let all = try await store.fetchAll()
        XCTAssertEqual(all.map(\.sortIndex), [0, 1, 2, 3, 4, 5])
        XCTAssertEqual(all.suffix(3).map(\.id), ["p2-0", "p2-1", "p2-2"])
    }

    func test_loadNextPage_offline_throwsEndOfCache() async throws {
        let repo = makeRepo(
            store: MockProfileStore(seed: Profile.page(1, perPage: 3)),
            monitor: MockNetworkMonitor(connected: false)
        )
        try await repo.bootstrap()

        await assertThrowsAsync(try await repo.loadNextPage()) {
            XCTAssertEqual($0 as? AppError, .endOfCache)
        }
    }

    func test_loadNextPage_doesNotAdvanceCursorOnFailure() async throws {
        let client = MockHTTPClient()
        client.responsesByPage["1"] = .success(RandomUserJSON.page(count: 3, idPrefix: "p1"))
        client.responsesByPage["2"] = .failure(.server(503))
        let store = MockProfileStore()
        let repo = makeRepo(client: client, store: store)
        try await repo.bootstrap() // empty cache -> fresh fetch, no background refresh

        await assertThrowsAsync(try await repo.loadNextPage()) // page 2 fails

        client.responsesByPage["2"] = .success(RandomUserJSON.page(count: 3, idPrefix: "p2"))
        try await repo.loadNextPage() // must retry page 2, not skip to 3

        let all = try await store.fetchAll()
        XCTAssertEqual(all.map(\.id), ["p1-0", "p1-1", "p1-2", "p2-0", "p2-1", "p2-2"])
    }

    // MARK: Merge semantics

    func test_refresh_preservesLocalStatusOverServerRow() async throws {
        let client = MockHTTPClient()
        client.responsesByPage["1"] = .success(RandomUserJSON.page(count: 3, idPrefix: "p1"))
        let store = MockProfileStore()
        let repo = makeRepo(client: client, store: store)
        try await repo.bootstrap()

        try await repo.updateStatus(id: "p1-0", to: .accepted)
        try await repo.refresh() // server row is .pending

        let refreshed = try await store.fetch(id: "p1-0")
        XCTAssertEqual(refreshed?.status, .accepted)
    }

    // MARK: Status mutation

    func test_updateStatus_persistenceFailure_rollsBackAndThrows() async throws {
        // Offline + seeded so bootstrap does no network and starts no background refresh —
        // keeps the emission sequence deterministic.
        let store = MockProfileStore(seed: [Profile.stub(id: "x", sortIndex: 0, status: .pending)])
        let repo = makeRepo(store: store, monitor: MockNetworkMonitor(connected: false))
        try await repo.bootstrap()

        var iterator = repo.profiles().makeAsyncIterator()
        _ = await iterator.next() // drain replayed current
        await store.setUpdateStatusError(.persistence)

        await assertThrowsAsync(try await repo.updateStatus(id: "x", to: .accepted)) {
            XCTAssertEqual($0 as? AppError, .persistence)
        }

        let optimistic = await iterator.next()
        let rolledBack = await iterator.next()
        XCTAssertEqual(optimistic?.first?.status, .accepted)
        XCTAssertEqual(rolledBack?.first?.status, .pending)
    }

    // MARK: Multi-subscriber

    func test_profiles_replaysAndBroadcastsToEverySubscriber() async throws {
        let client = MockHTTPClient()
        client.responsesByPage["1"] = .success(RandomUserJSON.page(count: 3, idPrefix: "p1"))
        let repo = makeRepo(client: client)
        try await repo.bootstrap() // current is now the 3 fetched profiles

        var a = repo.profiles().makeAsyncIterator()
        var b = repo.profiles().makeAsyncIterator()
        let replayA = await a.next()
        let replayB = await b.next()
        XCTAssertEqual(replayA?.count, 3)
        XCTAssertEqual(replayB?.count, 3)

        try await repo.updateStatus(id: "p1-0", to: .accepted)
        let updateA = await a.next()
        let updateB = await b.next()
        XCTAssertEqual(updateA?.first { $0.id == "p1-0" }?.status, .accepted)
        XCTAssertEqual(updateB?.first { $0.id == "p1-0" }?.status, .accepted)
    }
}

// MARK: - Async throwing assertion helper

func assertThrowsAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        XCTFail(message.isEmpty ? "Expected an error to be thrown" : message, file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
