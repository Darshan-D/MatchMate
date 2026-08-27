//
//  GetProfileUseCase.swift
//  MatchMate
//
//  Created by Darshan Dodia on 27/08/26.
//

import Foundation

protocol GetProfileUseCase {
    func execute(id: String) async throws -> Profile?
}

struct DefaultGetProfileUseCase: GetProfileUseCase {
    let repository: ProfileRepository

    func execute(id: String) async throws -> Profile? {
        return try await repository.profile(id: id)
    }
}
