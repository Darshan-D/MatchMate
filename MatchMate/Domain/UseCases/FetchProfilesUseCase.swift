//
//  UseCase.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation

// MARK: - Fetch Profiles Use Case

protocol FetchProfilesUseCase {
    func execute(page: Int) async throws -> [Profile]
}

struct DefaultFetchProfilesUseCase: FetchProfilesUseCase {
    let repository: ProfileRepository

    func execute(page: Int) async throws -> [Profile] {
        return try await repository.loadPage(page)
    }
}


