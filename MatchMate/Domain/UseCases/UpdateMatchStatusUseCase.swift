//
//  UpdateMatchStatusUseCase.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation

// MARK: - Update Match Status Use Case

@MainActor
protocol UpdateMatchStatusUseCase {
    func execute(id: String, status: MatchStatus) async throws
}

@MainActor
struct DefaultUpdateMatchStatusUseCase: UpdateMatchStatusUseCase {
    let repository: ProfileRepository

    func execute(id: String, status: MatchStatus) async throws {
        try await repository.updateStatus(id: id, status: status)
    }
}
