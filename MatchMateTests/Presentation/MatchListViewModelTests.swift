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
        let updateUseCase = DefaultUpdateMatchStatusUseCase(repository: mockRepository)

        viewModel = MatchListViewModel(
            fetchProfiles: fetchUseCase,
            updateStatus: updateUseCase,
            repository: mockRepository
        )
    }

    func testLoadInitial_PopulatesProfiles() async {
        // Arrange
        let mockProfile = Profile(id: "1", firstName: "John", lastName: "Doe", age: 30, city: "NY", state: "NY", country: "US", email: "test@test.com", phone: "123", nationality: "US", registeredDate: Date(), thumbnailURL: nil, largePhotoURL: nil, status: .pending)
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
        let profile1 = Profile(id: "1", firstName: "A", lastName: "B", age: 20, city: "C", state: "D", country: "E", email: "F", phone: "G", nationality: "H", registeredDate: Date(), thumbnailURL: nil, largePhotoURL: nil, status: .pending)
        let profile2 = Profile(id: "2", firstName: "X", lastName: "Y", age: 21, city: "C", state: "D", country: "E", email: "F", phone: "G", nationality: "H", registeredDate: Date(), thumbnailURL: nil, largePhotoURL: nil, status: .pending)

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
        let profile = Profile(id: "1", firstName: "John", lastName: "Doe", age: 30, city: "NY", state: "NY", country: "US", email: "test", phone: "123", nationality: "US", registeredDate: Date(), thumbnailURL: nil, largePhotoURL: nil, status: .pending)
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
        let profile = Profile(id: "1", firstName: "John", lastName: "Doe", age: 30, city: "NY", state: "NY", country: "US", email: "test", phone: "123", nationality: "US", registeredDate: Date(), thumbnailURL: nil, largePhotoURL: nil, status: .pending)
        viewModel.profiles = [profile]

        // Act
        await viewModel.loadNextPageIfNeeded(currentItem: profile)

        // Assert
        guard case .offlineNoMoreData = viewModel.error else {
            XCTFail("Expected offlineNoMoreData error")
            return
        }
    }
}
