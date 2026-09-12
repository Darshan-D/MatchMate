//
//  MatchDetailViewModelTests.swift
//  MatchMateTests
//

import XCTest
@testable import MatchMate

@MainActor
final class MatchDetailViewModelTests: XCTestCase {

    private var repository: MockProfileRepository!
    private var viewModel: MatchDetailViewModel!

    override func setUp() {
        super.setUp()
        repository = MockProfileRepository()
        viewModel = MatchDetailViewModel(id: "7", repository: repository)
    }

    private func start() {
        startObserving { [viewModel] in await viewModel?.start() }
    }

    func test_start_deliversProfileFromStream() async {
        await repository.seed([Profile.stub(id: "7", firstName: "Alice")])

        start()
        await waitUntil("profile delivered") { self.viewModel.profile?.firstName == "Alice" }

        XCTAssertNil(viewModel.error)
    }

    func test_start_profileAbsent_leavesProfileNil() async {
        await repository.seed([Profile.stub(id: "other")])

        start()
        for _ in 0..<50 { await Task.yield() } // let the stream deliver

        XCTAssertNil(viewModel.profile)
    }

    func test_accept_optimisticThenPersists() async {
        await repository.seed([Profile.stub(id: "7", status: .pending)])
        start()
        await waitUntil { self.viewModel.profile != nil }

        await viewModel.accept()
        await waitUntil("status accepted") { self.viewModel.profile?.status == .accepted }

        let updates = await repository.statusUpdates
        XCTAssertEqual(updates.map(\.status), [.accepted])
    }

    func test_decline_failure_rollsBackAndSurfacesError() async {
        await repository.seed([Profile.stub(id: "7", status: .pending)])
        await repository.setUpdateStatusError(.persistence)
        start()
        await waitUntil { self.viewModel.profile != nil }

        await viewModel.decline()
        await waitUntil("rolled back to pending") { self.viewModel.profile?.status == .pending }

        XCTAssertEqual(viewModel.error, .persistence)
    }

    func test_statusChangedOnList_reflectsInDetailWithoutReload() async {
        await repository.seed([Profile.stub(id: "7", status: .pending)])
        start()
        await waitUntil { self.viewModel.profile != nil }

        // A different observer (the list) changes the status.
        try? await repository.updateStatus(id: "7", to: .declined)

        await waitUntil("detail self-corrects") { self.viewModel.profile?.status == .declined }
    }
}
