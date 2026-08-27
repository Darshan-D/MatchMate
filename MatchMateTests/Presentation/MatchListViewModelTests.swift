//
//  MatchListViewModelTests.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import XCTest
@testable import MatchMate

@MainActor
final class MatchListViewModelTests: XCTestCase {
    var viewModel: MatchListViewModel!
    var mockRepository: MockProfileRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockProfileRepository()

        let fetchUseCase = DefaultFetchProfilesUseCase(repository: mockRepository)
        let cachedUseCase = DefaultGetCachedProfilesUseCase(repository: mockRepository)
        let updateUseCase = DefaultUpdateMatchStatusUseCase(repository: mockRepository)
        let resumePageUseCase = DefaultGetResumePageUseCase(repository: mockRepository)

        viewModel = MatchListViewModel(
            fetchProfiles: fetchUseCase,
            getCachedProfiles: cachedUseCase,
            updateStatus: updateUseCase,
            getResumePage: resumePageUseCase
        )
    }

    func testLoadInitial_PopulatesProfiles() async {
        // Arrange
        let mockProfile = Profile.stub(id: "1", firstName: "John", lastName: "Doe")
        mockRepository.remotePages[1] = [mockProfile]

        // Act
        await viewModel.loadInitial()

        // Assert
        XCTAssertEqual(viewModel.profiles.count, 1)
        XCTAssertEqual(viewModel.profiles.first?.id, "1")
        XCTAssertFalse(viewModel.isLoadingPage)
    }

    func testPagination_AppendsData_DoesNotReplace() async {
        // Arrange
        let profile1 = Profile.stub(id: "1", firstName: "A")
        let profile2 = Profile.stub(id: "2", firstName: "X")
        mockRepository.remotePages[1] = [profile1]
        mockRepository.remotePages[2] = [profile2]

        // Act
        await viewModel.loadInitial()
        await viewModel.loadNextPageIfNeeded(currentItem: profile1)

        // Assert
        XCTAssertEqual(viewModel.profiles.count, 2)
        XCTAssertTrue(viewModel.profiles.contains(where: { $0.id == "2" }))
    }

    func testAccept_OptimisticallyUpdatesUI_ThenPersists() async {
        // Arrange
        let profile = Profile.stub(id: "1", firstName: "John", lastName: "Doe")
        mockRepository.storage["1"] = profile
        viewModel.profiles = [profile] // Mock pre-loaded state

        // Act
        await viewModel.accept("1")

        // Assert - ViewModel state is updated (Optimistic UI)
        XCTAssertEqual(viewModel.profiles.first?.status, .accepted)
        // Assert - Repository state is updated (Persistence)
        XCTAssertEqual(mockRepository.storage["1"]?.status, .accepted)
    }

    func testOfflinePagination_SurfacesError_DoesNotCrash() async {
        // Arrange
        mockRepository.isReachable = false
        mockRepository.shouldThrowError = .offlineNoMoreData
        let profile = Profile.stub(id: "1", firstName: "John", lastName: "Doe")
        viewModel.profiles = [profile]

        // Act
        await viewModel.loadNextPageIfNeeded(currentItem: profile)

        // Assert
        guard case .offlineNoMoreData = viewModel.error else {
            XCTFail("Expected offlineNoMoreData error")
            return
        }
    }

    func testLoadInitial_OfflineWithNoCache_SurfacesNetworkError() async {
        // Arrange
        mockRepository.isReachable = false
        mockRepository.storage = [:] // Guarantee empty cache

        // Act
        await viewModel.loadInitial()

        // Assert
        XCTAssertTrue(viewModel.profiles.isEmpty) // Profiles must remain empty

        guard case .network = viewModel.error else {
            XCTFail("Expected network error to trigger the OfflineEmptyStateView")
            return
        }
    }

    func testDecline_OptimisticallyUpdatesUI_ThenPersists() async {
        // Arrange
        let profile = Profile.stub(id: "1", firstName: "John", lastName: "Doe")
        mockRepository.storage["1"] = profile
        viewModel.profiles = [profile] // Mock pre-loaded state

        // Act
        await viewModel.decline("1")

        // Assert - ViewModel state is updated (Optimistic UI)
        XCTAssertEqual(viewModel.profiles.first?.status, .declined)
        // Assert - Repository state is updated (Persistence)
        XCTAssertEqual(mockRepository.storage["1"]?.status, .declined)
    }

    func testUpdateStatus_Failure_RollsBackToPreviousState() async {
        // Arrange
        let profile = Profile.stub(id: "1", firstName: "John", lastName: "Doe")
        mockRepository.storage["1"] = profile
        viewModel.profiles = [profile] // Mock pre-loaded state

        // Force the persistence layer to fail
        mockRepository.shouldThrowError = .persistence(NSError(domain: "Test", code: 1))

        // Act
        await viewModel.accept("1")

        // Assert - UI State rolls back to pending instead of getting stuck on accepted
        XCTAssertEqual(viewModel.profiles.first?.status, .pending)
        // Assert - Error surfaced to be displayed in the ErrorBannerView
        XCTAssertNotNil(viewModel.error)
    }

    func testLoadInitial_WithWarmCache_ResumesFromCorrectPage() async {
        // Arrange: simulate a previous session that had already reached page 3
        let page1 = [Profile.stub(id: "1", firstName: "A")]
        let page3 = [Profile.stub(id: "3", firstName: "X")]
        mockRepository.remotePages[1] = page1
        mockRepository.remotePages[3] = page3
        _ = try! await mockRepository.loadPage(1)
        _ = try! await mockRepository.loadPage(3)   // simulates prior session reaching page 3
        XCTAssertEqual(mockRepository.storage.count, 2)

        let page4 = [Profile(id: "4", firstName: "M", lastName: "N", age: 22, city: "C", state: "D", country: "E", email: "F", phone: "G", nationality: "H", registeredDate: Date(), thumbnailURL: nil, largePhotoURL: nil, status: .pending)]
        mockRepository.remotePages[4] = page4   // the page that SHOULD get requested next

        // Act: fresh ViewModel picks up the "warm" mock repository
        await viewModel.loadInitial()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.profiles.last!)

        // Assert: should have requested page 4, not page 2
        XCTAssertTrue(viewModel.profiles.contains(where: { $0.id == "4" }))
    }
}
