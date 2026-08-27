//
//  MockProfileRepository.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation
@testable import MatchMate

@MainActor
final class MockProfileRepository: ProfileRepository {
    // In-memory storage acting as our local database
    var storage: [String: Profile] = [:]

    // Configurable behaviors for testing different states
    var isReachable: Bool = true
    var shouldThrowError: ProfileRepositoryError?

    // Pre-canned data for pagination
    var remotePages: [Int: [Profile]] = [:]

    // Track what page was most recently requested (for test assertions)
    private(set) var highestLoadedPage: Int = 0

    func loadPage(_ page: Int) async throws -> [Profile] {
        if let error = shouldThrowError { throw error }

        if isReachable {
            let fetched = remotePages[page] ?? []
            for profile in fetched {
                // Preserve existing status if it exists, otherwise insert
                if let existing = storage[profile.id] {
                    var updated = profile
                    updated.status = existing.status
                    storage[profile.id] = updated
                } else {
                    storage[profile.id] = profile
                }
            }
            highestLoadedPage = max(highestLoadedPage, page)
        } else {
            if storage.isEmpty {
                throw ProfileRepositoryError.network(URLError(.notConnectedToInternet))
            }

            if page > 1 && storage.isEmpty {
                throw ProfileRepositoryError.offlineNoMoreData
            }
        }
        return try await cachedProfiles()
    }

    func cachedProfiles() async throws -> [Profile] {
        if let error = shouldThrowError { throw error }
        return Array(storage.values).sorted(by: { $0.firstName < $1.firstName }) // Arbitrary sort for stability
    }

    func updateStatus(id: String, status: MatchStatus) async throws {
        if let error = shouldThrowError { throw error }
        storage[id]?.status = status
    }

    func profile(id: String) async throws -> Profile? {
        if let error = shouldThrowError { throw error }
        return storage[id]
    }

    func resumePage() async throws -> Int {
        if let error = shouldThrowError { throw error }
        return highestLoadedPage == 0 ? 1 : highestLoadedPage
    }
}
