//
//  ProfileEntityIntegrationTests.swift
//  MatchMateTests
//
//  Exercises the real SwiftData-backed ProfileStore against an in-memory container.
//

import XCTest
import SwiftData
@testable import MatchMate

final class ProfileStoreTests: XCTestCase {

    private var container: ModelContainer!
    private var store: ProfileStore!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: ProfileEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        store = ProfileStore(modelContainer: container)
    }

    func test_upsert_insertsThenUpdatesInPlace() async throws {
        try await store.upsert([Profile.stub(id: "1", firstName: "Alice", sortIndex: 0)])
        try await store.upsert([Profile.stub(id: "1", firstName: "Alicia", city: "Paris", sortIndex: 0)])

        let all = try await store.fetchAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.firstName, "Alicia")
        XCTAssertEqual(all.first?.city, "Paris")
    }

    func test_upsert_preservesLocalStatusDecision() async throws {
        try await store.upsert([Profile.stub(id: "1", sortIndex: 0, status: .pending)])
        try await store.updateStatus(id: "1", to: .declined)

        // API returns the same person again (defaults to .pending) with fresh fields.
        try await store.upsert([Profile.stub(id: "1", firstName: "Renamed", sortIndex: 0, status: .pending)])

        let fetched = try await store.fetch(id: "1")
        XCTAssertEqual(fetched?.firstName, "Renamed")
        XCTAssertEqual(fetched?.status, .declined)
    }

    func test_fetchAll_isOrderedBySortIndex() async throws {
        try await store.upsert([
            Profile.stub(id: "c", sortIndex: 2),
            Profile.stub(id: "a", sortIndex: 0),
            Profile.stub(id: "b", sortIndex: 1)
        ])

        let ids = try await store.fetchAll().map(\.id)
        XCTAssertEqual(ids, ["a", "b", "c"])
    }

    func test_updateStatus_persists() async throws {
        try await store.upsert([Profile.stub(id: "1", sortIndex: 0)])
        try await store.updateStatus(id: "1", to: .accepted)

        let fetched = try await store.fetch(id: "1")
        XCTAssertEqual(fetched?.status, .accepted)
    }

    func test_updateStatus_unknownId_throwsPersistence() async {
        do {
            try await store.updateStatus(id: "missing", to: .accepted)
            XCTFail("expected persistence error")
        } catch {
            XCTAssertEqual(error as? AppError, .persistence)
        }
    }

    func test_highestLoadedPage_derivedFromSortIndex() async throws {
        let empty = try await store.highestLoadedPage(resultsPerPage: 10)
        XCTAssertEqual(empty, 0)

        try await store.upsert(Profile.page(1, perPage: 10) + Profile.page(2, perPage: 10))
        let loaded = try await store.highestLoadedPage(resultsPerPage: 10)
        XCTAssertEqual(loaded, 2)
    }

    func test_registeredDate_roundTripsThroughStore() async throws {
        let date = Date(timeIntervalSince1970: 1_400_000_000)
        try await store.upsert([Profile.stub(id: "1", registeredDate: date, sortIndex: 0)])

        let fetched = try await store.fetch(id: "1")
        XCTAssertEqual(fetched?.registeredDate?.timeIntervalSince1970, date.timeIntervalSince1970)
    }
}
