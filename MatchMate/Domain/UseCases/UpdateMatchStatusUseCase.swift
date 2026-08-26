//
//  UpdateMatchStatusUseCase.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation

// MARK: - Update Match Status Use Case

protocol UpdateMatchStatusUseCase {
    func execute(id: String, status: MatchStatus) async throws
}

struct DefaultUpdateMatchStatusUseCase: UpdateMatchStatusUseCase {
    let repository: ProfileRepository

    func execute(id: String, status: MatchStatus) async throws {
        // Any specific business logic (e.g., checking if transitions are allowed) would go here.
        // For now, we allow toggling to support our assumed one-directional-but-reversible UX rule.
        try await repository.updateStatus(id: id, status: status)
    }
}
