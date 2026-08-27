//
//  AppComposition.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation
import SwiftData

/// Composition root for protocol-based dependency injection
enum AppComposition {
    @MainActor
    static func makeMatchListViewModel(context: ModelContext) -> MatchListViewModel {
        let remote = RandomUserRemoteDataSource(session: .shared)
        let local = SwiftDataLocalDataSource(context: context)
        let repo = ProfileRepositoryImpl(remote: remote, local: local)

        let fetchUseCase = DefaultFetchProfilesUseCase(repository: repo)
        let getCachedUseCase = DefaultGetCachedProfilesUseCase(repository: repo)
        let updateUseCase = DefaultUpdateMatchStatusUseCase(repository: repo)
        let getResumePageUseCase = DefaultGetResumePageUseCase(repository: repo)

        return MatchListViewModel(
            fetchProfiles: fetchUseCase,
            getCachedProfiles: getCachedUseCase,
            updateStatus: updateUseCase,
            getResumePage: getResumePageUseCase
        )
    }

    @MainActor
    static func makeMatchDetailViewModel(profileId: String, context: ModelContext) -> MatchDetailViewModel {
        let remote = RandomUserRemoteDataSource(session: .shared)
        let local = SwiftDataLocalDataSource(context: context)
        let repo = ProfileRepositoryImpl(remote: remote, local: local)

        let getProfileUseCase = DefaultGetProfileUseCase(repository: repo)
        let updateUseCase = DefaultUpdateMatchStatusUseCase(repository: repo)

        return MatchDetailViewModel(
            profileId: profileId,
            getProfile: getProfileUseCase,
            updateStatus: updateUseCase
        )
    }
}
