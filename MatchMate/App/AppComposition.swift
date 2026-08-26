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
        // These concrete types will be implemented in the Data layer (Phase 2)
        let remote = RandomUserRemoteDataSource(session: .shared)
        let local = SwiftDataLocalDataSource(context: context)
        let repo = ProfileRepositoryImpl(remote: remote, local: local, reachability: NetworkMonitor.shared)

        let fetchUseCase = DefaultFetchProfilesUseCase(repository: repo)
        let updateUseCase = DefaultUpdateMatchStatusUseCase(repository: repo)

        return MatchListViewModel(
            fetchProfiles: fetchUseCase,
            updateStatus: updateUseCase,
            repository: repo
        )
    }

    @MainActor
    static func makeMatchDetailViewModel(profileId: String, context: ModelContext) -> MatchDetailViewModel {
        let remote = RandomUserRemoteDataSource(session: .shared)
        let local = SwiftDataLocalDataSource(context: context)
        let repo = ProfileRepositoryImpl(remote: remote, local: local, reachability: NetworkMonitor.shared)

        let updateUseCase = DefaultUpdateMatchStatusUseCase(repository: repo)

        return MatchDetailViewModel(
            profileId: profileId,
            repository: repo,
            updateStatus: updateUseCase
        )
    }
}
