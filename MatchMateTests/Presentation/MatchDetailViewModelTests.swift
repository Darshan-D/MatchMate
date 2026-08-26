//
//  MatchDetailViewModelTests.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import XCTest
@testable import MatchMate

@MainActor
final class MatchDetailViewModelTests: XCTestCase {
    var viewModel: MatchDetailViewModel!
    var mockRepository: MockProfileRepository!

    override func setUp() {
        super.setUp()
        // We reuse the exact same mockProfileRepository we built for the list tests
        mockRepository = MockProfileRepository()
        let updateUseCase = DefaultUpdateMatchStatusUseCase(repository: mockRepository)

        viewModel = MatchDetailViewModel(
            profileId: "1",
            repository: mockRepository,
            updateStatus: updateUseCase
        )
    }

    func testLoadProfile_Success_PopulatesProfile() async {
        // Arrange
        let mockProfile = Profile(id: "1", firstName: "Alice", lastName: "Smith", age: 28, city: "London", state: "ENG", country: "UK", email: "alice@test.com", phone: "555", nationality: "GB", registeredDate: Date(), thumbnailURL: nil, largePhotoURL: nil, status: .pending)
        mockRepository.storage["1"] = mockProfile

        // Act
        await viewModel.loadProfile()

        // Assert
        XCTAssertNotNil(viewModel.profile)
        XCTAssertEqual(viewModel.profile?.firstName, "Alice")
        XCTAssertNil(viewModel.error)
    }

    func testLoadProfile_Failure_SurfacesError() async {
        // Arrange
        mockRepository.shouldThrowError = .persistence(NSError(domain: "Test", code: 1))

        // Act
        await viewModel.loadProfile()

        // Assert
        XCTAssertNil(viewModel.profile)
        XCTAssertNotNil(viewModel.error)
    }

    func testAccept_OptimisticallyUpdatesUI_AndPersistsToDatabase() async {
        // Arrange
        let mockProfile = Profile(id: "1", firstName: "Alice", lastName: "Smith", age: 28, city: "London", state: "ENG", country: "UK", email: "alice@test.com", phone: "555", nationality: "GB", registeredDate: Date(), thumbnailURL: nil, largePhotoURL: nil, status: .pending)
        mockRepository.storage["1"] = mockProfile
        await viewModel.loadProfile() // Load the profile into the ViewModel state

        // Act
        await viewModel.accept()

        // Assert - ViewModel state updated immediately (Optimistic UI)
        XCTAssertEqual(viewModel.profile?.status, .accepted)
        // Assert - Changes were sent to the database
        XCTAssertEqual(mockRepository.storage["1"]?.status, .accepted)
        XCTAssertNil(viewModel.error)
    }

    func testDecline_Failure_RollsBackStatusToPreviousState() async {
        // Arrange
        let mockProfile = Profile(id: "1", firstName: "Alice", lastName: "Smith", age: 28, city: "London", state: "ENG", country: "UK", email: "alice@test.com", phone: "555", nationality: "GB", registeredDate: Date(), thumbnailURL: nil, largePhotoURL: nil, status: .pending)
        mockRepository.storage["1"] = mockProfile
        await viewModel.loadProfile()

        // Force the database update to fail
        mockRepository.shouldThrowError = .persistence(NSError(domain: "Test", code: 1))

        // Act
        await viewModel.decline()

        // Assert - UI State rolls back to pending instead of getting stuck on declined
        XCTAssertEqual(viewModel.profile?.status, .pending)
        // Assert - Error surfaced to be displayed in the ErrorBannerView
        XCTAssertNotNil(viewModel.error)
    }
}
