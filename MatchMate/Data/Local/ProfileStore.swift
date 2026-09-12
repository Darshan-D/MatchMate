//
//  ProfileStore.swift
//  MatchMate
//

import Foundation
import SwiftData
import os

/// SwiftData persistence, isolated on its own actor so reads/writes never touch the main thread.
/// Exposes only `Sendable` domain types — `ProfileEntity` and `ModelContext` stay inside.
protocol ProfilePersisting: Sendable {
    func fetchAll() async throws -> [Profile]
    func fetch(id: String) async throws -> Profile?
    /// Insert new rows / update existing ones in place. Never overwrites `status` — a local
    /// Accept/Decline always wins over a re-fetched server row.
    func upsert(_ profiles: [Profile]) async throws
    func updateStatus(id: String, to status: MatchStatus) async throws
    /// Highest page represented in the cache, derived from `sortIndex`. `0` when empty.
    func highestLoadedPage(resultsPerPage: Int) async throws -> Int
}

@ModelActor
actor ProfileStore: ProfilePersisting {

    func fetchAll() throws -> [Profile] {
        let descriptor = FetchDescriptor<ProfileEntity>(sortBy: [SortDescriptor(\.sortIndex)])
        return try modelContext.fetch(descriptor).map(\.domain)
    }

    func fetch(id: String) throws -> Profile? {
        try entity(id: id)?.domain
    }

    func upsert(_ profiles: [Profile]) throws {
        for profile in profiles {
            if let existing = try entity(id: profile.id) {
                existing.apply(profile)
            } else {
                let entity = ProfileEntity(id: profile.id)
                entity.apply(profile)
                entity.status = profile.status // seeded once, on insert
                modelContext.insert(entity)
            }
        }
        try modelContext.save()
    }

    func updateStatus(id: String, to status: MatchStatus) throws {
        guard let entity = try entity(id: id) else {
            Log.persistence.error("updateStatus: no row for id \(id, privacy: .public)")
            throw AppError.persistence
        }
        entity.status = status
        try modelContext.save()
    }

    func highestLoadedPage(resultsPerPage: Int) throws -> Int {
        guard resultsPerPage > 0 else { return 0 }
        var descriptor = FetchDescriptor<ProfileEntity>(sortBy: [SortDescriptor(\.sortIndex, order: .reverse)])
        descriptor.fetchLimit = 1
        guard let maxIndex = try modelContext.fetch(descriptor).first?.sortIndex else { return 0 }
        return maxIndex / resultsPerPage + 1
    }

    private func entity(id: String) throws -> ProfileEntity? {
        var descriptor = FetchDescriptor<ProfileEntity>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
