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
            let domainProfiles = dtos.compactMap(mapToDomain)

            do {
                try local.upsert(domainProfiles, page: page)
            } catch {
                throw ProfileRepositoryError.persistence(error)
            }
        } else {
            // Check if we actually have data for this page cached offline
            let cached = try cachedProfiles()
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

    // Helper to map DTO -> Domain Entity
    private func mapToDomain(_ dto: ProfileDTO) -> Profile? {
        let formatter = ISO8601DateFormatter()
        // RandomUser API sometimes appends fraction seconds; adjusting if needed
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: dto.registered.date) ?? Date()

        return Profile(
            id: dto.login.uuid,
            firstName: dto.name.first,
            lastName: dto.name.last,
            age: dto.dob.age,
            city: dto.location.city,
            state: dto.location.state,
            country: dto.location.country,
            email: dto.email,
            phone: dto.phone,
            nationality: dto.nat,
            registeredDate: date,
            thumbnailURL: URL(string: dto.picture.medium),
            largePhotoURL: URL(string: dto.picture.large),
            status: .pending // Defaults to pending. Local db upsert preserves true status.
        )
    }
}
