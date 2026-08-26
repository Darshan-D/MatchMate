//
//  ProfileRepositoryImpl.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation

@MainActor
final class ProfileRepositoryImpl: ProfileRepository {
    private let remote: RemoteProfileDataSource
    private let local: LocalProfileDataSource

    private let resultsPerPage = 10
    private let apiSeed = "matchmate" // Stable seed as required by assignment

    init(remote: RemoteProfileDataSource, local: LocalProfileDataSource) {
        self.remote = remote
        self.local = local
    }

    func loadPage(_ page: Int) async throws -> [Profile] {
        do {
            // 1. ALWAYS attempt the network request first.
            // URLSession handles immediate connection restoration better than NWPathMonitor.
            let dtos = try await remote.fetchPage(page, results: resultsPerPage, seed: apiSeed)
            let domainProfiles = dtos.map { $0.toDomain() }

            try local.upsert(domainProfiles, page: page)

        } catch {
            // 2. If the network request fails (or times out because you are actually offline),
            // we catch the error and fallback to the cache.
            let cached = try await cachedProfiles()

            // Fully offline + no cache on first launch
            if cached.isEmpty {
                throw ProfileRepositoryError.network(URLError(.notConnectedToInternet))
            }

            // Trying to paginate past what is saved offline
            let expectedCount = page * resultsPerPage
            if cached.count < expectedCount && page > 1 {
                throw ProfileRepositoryError.offlineNoMoreData
            }
        }

        // 3. Always return the local cache as the source of truth
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
