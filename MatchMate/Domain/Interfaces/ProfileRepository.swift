//
//  ProfileRepository.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation

@MainActor
protocol ProfileRepository {
    /// Fetches a page from remote (if reachable), merges + persists to local store,
    /// returns the full up-to-date local list (cache is source of truth for reads).
    func loadPage(_ page: Int) async throws -> [Profile]

    /// Reads whatever is cached locally, regardless of connectivity.
    func cachedProfiles() async throws -> [Profile]

    /// Persists a status change (Accept/Decline) locally.
    func updateStatus(id: String, status: MatchStatus) async throws

    /// Fetches a single profile for the detail screen.
    func profile(id: String) async throws -> Profile?

    /// Returns next page to fetch
    func resumePage() async throws -> Int
}
