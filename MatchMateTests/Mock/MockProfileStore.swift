//
//  MockProfileStore.swift
//  MatchMateTests
//

import Foundation
@testable import MatchMate

/// In-memory `ProfilePersisting` for repository tests. Mirrors the real store's contract:
/// `upsert` never overwrites `status`; reads come back sorted by `sortIndex`.
actor MockProfileStore: ProfilePersisting {
    private var storage: [String: Profile] = [:]
    var updateStatusError: AppError?

    init(seed: [Profile] = []) {
        for profile in seed { storage[profile.id] = profile }
    }

    func fetchAll() async throws -> [Profile] {
        storage.values.sorted { $0.sortIndex < $1.sortIndex }
    }

    func fetch(id: String) async throws -> Profile? {
        storage[id]
    }

    func upsert(_ profiles: [Profile]) async throws {
        for incoming in profiles {
            if var existing = storage[incoming.id] {
                let keptStatus = existing.status
                existing = incoming
                existing.status = keptStatus
                storage[incoming.id] = existing
            } else {
                storage[incoming.id] = incoming
            }
        }
    }

    func updateStatus(id: String, to status: MatchStatus) async throws {
        if let updateStatusError { throw updateStatusError }
        storage[id]?.status = status
    }

    func highestLoadedPage(resultsPerPage: Int) async throws -> Int {
        guard resultsPerPage > 0,
              let maxIndex = storage.values.map(\.sortIndex).max() else { return 0 }
        return maxIndex / resultsPerPage + 1
    }

    func setUpdateStatusError(_ error: AppError?) { updateStatusError = error }
}
