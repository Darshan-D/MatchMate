//
//  GetCachedProfilesUseCase.swift
//  MatchMate
//
//  Created by Darshan Dodia on 27/08/26.
//

import Foundation

protocol GetCachedProfilesUseCase {
    func execute() async throws -> [Profile]
}

struct DefaultGetCachedProfilesUseCase: GetCachedProfilesUseCase {
    let repository: ProfileRepository

    func execute() async throws -> [Profile] {
        return try await repository.cachedProfiles()
    }
}
