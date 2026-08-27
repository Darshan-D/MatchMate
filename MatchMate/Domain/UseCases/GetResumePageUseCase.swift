//
//  GetResumePageUseCase.swift
//  MatchMate
//
//  Created by Darshan Dodia on 27/08/26.
//

import Foundation

protocol GetResumePageUseCase {
    func execute() async throws -> Int
}

struct DefaultGetResumePageUseCase: GetResumePageUseCase {
    let repository: ProfileRepository
    func execute() async throws -> Int {
        try await repository.resumePage()
    }
}
