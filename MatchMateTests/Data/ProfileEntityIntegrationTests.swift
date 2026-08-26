//
//  ProfileEntityIntegrationTests.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import XCTest
import SwiftData
@testable import MatchMate

@MainActor
final class ProfileEntityIntegrationTests: XCTestCase {
    var container: ModelContainer!
    var localDataSource: SwiftDataLocalDataSource!

    override func setUpWithError() throws {
        // STRICT REQUIREMENT: In-memory configuration for test isolation
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: ProfileEntity.self, configurations: config)
        localDataSource = SwiftDataLocalDataSource(context: container.mainContext)
    }

    func testUpsert_And_UpdateStatus_PersistsCorrectly() throws {
        // Arrange
        let profile = Profile(id: "123", firstName: "Alice", lastName: "Smith", age: 28, city: "London", state: "ENG", country: "UK", email: "alice@test.com", phone: "555", nationality: "GB", registeredDate: Date(), thumbnailURL: nil, largePhotoURL: nil, status: .pending)

        // Act: Insert
        try localDataSource.upsert([profile], page: 1)

        // Act: Update Status
        try localDataSource.updateStatus(id: "123", status: .accepted)

        // Assert
        let fetched = try localDataSource.fetch(id: "123")
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.status, .accepted)
    }
}
