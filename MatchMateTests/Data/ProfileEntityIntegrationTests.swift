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
        // In-memory configuration for test isolation
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: ProfileEntity.self, configurations: config)
        localDataSource = SwiftDataLocalDataSource(context: container.mainContext)
    }

    func testUpsert_And_UpdateStatus_PersistsCorrectly() throws {
        // Arrange
        let profile = Profile.stub(id: "123",
                                   firstName: "Alice",
                                   lastName: "Smith",
                                   age: 28,
                                   city: "London",
                                   country: "UK",
                                   email: "alice@test.com",
                                   status: .pending)

        // Act: Insert
        try localDataSource.upsert([profile], page: 1)

        // Act: Update Status
        try localDataSource.updateStatus(id: "123", status: .accepted)

        // Assert
        let fetched = try localDataSource.fetch(id: "123")
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.status, .accepted)
    }

    func testUpsert_PreservesExistingStatusDecision() throws {
        // 1. Arrange: Insert a fresh profile from the API
        let initialProfile = Profile.stub(id: "456",
                                          firstName: "Bob",
                                          lastName: "Jones",
                                          age: 30,
                                          city: "NY",
                                          country: "US",
                                          status: .pending)
        try localDataSource.upsert([initialProfile], page: 1)

        // 2. Act: The user makes a definitive decision locally
        try localDataSource.updateStatus(id: "456", status: .declined)

        // 3. Act: Simulate a relaunch/pagination where the API returns the same user,
        // defaulting to .pending, but perhaps with updated remote data (e.g., moved to Boston).
        let refreshedProfile = Profile.stub(id: "456",
                                            firstName: "Robert",
                                            lastName: "Jones",
                                            age: 31,
                                            city: "Boston",
                                            country: "US",
                                            status: .pending)

        try localDataSource.upsert([refreshedProfile], page: 1)

        // 4. Assert
        let fetched = try localDataSource.fetch(id: "456")
        XCTAssertNotNil(fetched)

        // Verify the merge actually happened (metadata was updated)
        XCTAssertEqual(fetched?.firstName, "Robert")
        XCTAssertEqual(fetched?.city, "Boston")

        // Verify the local decision survived the network merge
        XCTAssertEqual(fetched?.status, .declined)
    }
}
