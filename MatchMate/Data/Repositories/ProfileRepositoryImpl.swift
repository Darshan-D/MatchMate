//
//  ProfileRepositoryImpl.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation

final class ProfileRepositoryImpl: ProfileRepository {
    private let remote: RemoteProfileDataSource
    private let local: LocalProfileDataSource
    private let reachability: Reachable

    private let resultsPerPage = 10
    private let apiSeed = "matchmate" // Stable seed as required by assignment

    init(remote: RemoteProfileDataSource, local: LocalProfileDataSource, reachability: Reachable) {
        self.remote = remote
        self.local = local
        self.reachability = reachability
    }

    func loadPage(_ page: Int) async throws -> [Profile] {
        if reachability.isConnected {
            let dtos = try await remote.fetchPage(page, results: resultsPerPage, seed: apiSeed)
            let domainProfiles = dtos.map { $0.toDomain() }

            do {
                try local.upsert(domainProfiles, page: page)
            } catch {
                throw ProfileRepositoryError.persistence(error)
            }
        } else {
            // Check if we actually have data for this page cached offline
            let cached = try await cachedProfiles()
            let expectedCount = page * resultsPerPage
            // If the user tries to paginate past what is locally saved while offline
            if cached.count < expectedCount && page > 1 {
                throw ProfileRepositoryError.offlineNoMoreData
            }
        }

        // The cache is always the source of truth for reads
        return try await cachedProfiles()
    }

    func cachedProfiles() async throws -> [Profile] {
        do {
            return try local.fetchAll()
        } catch {
            throw ProfileRepositoryError.persistence(error)
        }
    }

    func updateStatus(id: String, status: MatchStatus) async throws {
        do {
            try local.updateStatus(id: id, status: status)
        } catch {
            throw ProfileRepositoryError.persistence(error)
        }
    }

    func profile(id: String) async throws -> Profile? {
        do {
            return try local.fetch(id: id)
        } catch {
            throw ProfileRepositoryError.persistence(error)
        }
    }
}
