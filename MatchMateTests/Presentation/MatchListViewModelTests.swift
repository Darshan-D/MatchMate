//
//  MatchListViewModelTests.swift
//  MatchMateTests
//

import XCTest
@testable import MatchMate

@MainActor
final class MatchListViewModelTests: XCTestCase {

    private var repository: MockProfileRepository!
    private var viewModel: MatchListViewModel!

    override func setUp() {
        super.setUp()
        repository = MockProfileRepository()
        viewModel = MatchListViewModel(repository: repository)
    }

    private func start() {
        startObserving { [viewModel] in await viewModel?.start() }
    }

    // MARK: Initial load

    func test_start_populatesFromCache() async {
        await repository.seed(Profile.page(1, perPage: 3))

        start()
        await waitUntil("profiles loaded") { self.viewModel.profiles.count == 3 }

        XCTAssertEqual(viewModel.profiles.map(\.id), ["0", "1", "2"])
        XCTAssertFalse(viewModel.isLoadingInitial)
    }

    func test_start_emptyCacheOffline_showsLoadFailure() async {
        await repository.setBootstrapError(.offlineNoCache)

        start()
        await waitUntil("error surfaced") { self.viewModel.error == .offlineNoCache }

        XCTAssertTrue(viewModel.profiles.isEmpty)
        XCTAssertEqual(viewModel.loadFailure, .offlineNoCache)
    }

    // MARK: Pagination

    func test_loadMore_appendsNextPageInOrder() async {
        await repository.setPages([1: Profile.page(1, perPage: 3), 2: Profile.page(2, perPage: 3)])

        start()
        await waitUntil { self.viewModel.profiles.count == 3 }

        await viewModel.loadMoreIfNeeded(currentItem: viewModel.profiles.last!)
        await waitUntil("second page appended") { self.viewModel.profiles.count == 6 }

        XCTAssertEqual(viewModel.profiles.map(\.sortIndex), [0, 1, 2, 3, 4, 5])
    }

    func test_loadMore_onlyTriggersForLastItem() async {
        await repository.setPages([1: Profile.page(1, perPage: 3), 2: Profile.page(2, perPage: 3)])

        start()
        await waitUntil { self.viewModel.profiles.count == 3 }

        await viewModel.loadMoreIfNeeded(currentItem: viewModel.profiles.first!)

        let calls = await repository.loadNextPageCallCount
        XCTAssertEqual(calls, 0)
    }

    func test_loadMore_offlinePastCache_surfacesEndOfCache_keepsList() async {
        await repository.seed(Profile.page(1, perPage: 3), pagesAlreadyLoaded: 1)
        await repository.setNextPageError(.endOfCache)

        start()
        await waitUntil { self.viewModel.profiles.count == 3 }

        await viewModel.loadMoreIfNeeded(currentItem: viewModel.profiles.last!)

        XCTAssertEqual(viewModel.error, .endOfCache)
        XCTAssertEqual(viewModel.profiles.count, 3, "list stays visible")
    }

    // MARK: Optimistic status

    func test_accept_updatesImmediatelyAndPersists() async {
        await repository.seed([Profile.stub(id: "7", status: .pending)])

        start()
        await waitUntil { self.viewModel.profiles.count == 1 }

        await viewModel.accept("7")
        await waitUntil("status reflected") { self.viewModel.profiles.first?.status == .accepted }

        let updates = await repository.statusUpdates
        XCTAssertEqual(updates.map(\.status), [.accepted])
    }

    func test_updateStatus_failure_rollsBackAndSurfacesError() async {
        await repository.seed([Profile.stub(id: "7", status: .pending)])
        await repository.setUpdateStatusError(.persistence)

        start()
        await waitUntil { self.viewModel.profiles.count == 1 }

        await viewModel.decline("7")
        await waitUntil("rolled back") { self.viewModel.profiles.first?.status == .pending }

        XCTAssertEqual(viewModel.error, .persistence)
    }

    // MARK: Live sync

    func test_statusChangedOutsideViewModel_propagatesIntoList() async {
        await repository.seed([Profile.stub(id: "7", status: .pending)])

        start()
        await waitUntil { self.viewModel.profiles.count == 1 }

        // Simulates the detail screen (or any other observer) making the change.
        try? await repository.updateStatus(id: "7", to: .accepted)

        await waitUntil("list self-corrects") { self.viewModel.profiles.first?.status == .accepted }
    }

    // MARK: Connectivity

    func test_connectivityStream_togglesOfflineFlag() async {
        await repository.seed(Profile.page(1, perPage: 1))

        start()
        await waitUntil { !self.viewModel.profiles.isEmpty }
        XCTAssertFalse(viewModel.isOffline)

        await repository.setConnected(false)
        await waitUntil("offline flag set") { self.viewModel.isOffline }

        await repository.setConnected(true)
        await waitUntil("offline flag cleared") { !self.viewModel.isOffline }
    }

    func test_refresh_forwardsToRepository() async {
        await repository.seed(Profile.page(1, perPage: 1))

        start()
        await viewModel.refresh()

        let count = await repository.refreshCallCount
        XCTAssertEqual(count, 1)
    }
}
