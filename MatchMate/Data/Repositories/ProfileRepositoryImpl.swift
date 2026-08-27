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
            // We ALWAYS attempt the network request first.
            let dtos = try await remote.fetchPage(page, results: resultsPerPage, seed: apiSeed)
            let domainProfiles = dtos.map { $0.toDomain() }

            try local.upsert(domainProfiles, page: page)

        } catch let error as ProfileRepositoryError {
            if case .network(let urlError) = error {
                print("⚠️ [WARN][ProfileRepositoryImpl] Network error fetching page \(page): \(urlError.localizedDescription). Attempting offline fallback...")
                return try await handleOfflineFallback(page: page)
            } else {
                print("❌ [ERROR][ProfileRepositoryImpl] Repository error on page \(page): \(error)")
                throw error
            }
        } catch {
            print("❌ [ERROR][ProfileRepositoryImpl] Unexpected persistence error on page \(page): \(error)")
            throw ProfileRepositoryError.persistence(error)
        }

        // Always return the local cache as the source of truth for successful fetches
        return try await cachedProfiles()
    }

    private func handleOfflineFallback(page: Int) async throws -> [Profile] {
        let cached = try await cachedProfiles()

        // Fully offline + no cache on first launch
        if cached.isEmpty {
            print("❌ [ERROR][ProfileRepositoryImpl] Offline fallback failed: No cached profiles available for first launch.")
            throw ProfileRepositoryError.network(URLError(.notConnectedToInternet))
        }

        // Trying to paginate past what is saved offline
        let expectedCount = page * resultsPerPage
        if cached.count < expectedCount && page > 1 {
            print("⚠️ [WARN][ProfileRepositoryImpl] Offline fallback stopped: Tried to load page \(page) but only \(cached.count) profiles are cached offline.")
            throw ProfileRepositoryError.offlineNoMoreData
        }

        print("✅ [SUCCESS][ProfileRepositoryImpl] Offline fallback successful: Serving \(cached.count) profiles from local cache.")
        return cached
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

    func resumePage() async throws -> Int {
        do {
            let highest = try local.highestFetchedPage()
            return highest == 0 ? 1 : highest   // no cache yet → start at 1
        } catch {
            throw ProfileRepositoryError.persistence(error)
        }
    }
}
