//
//  AppEnvironment.swift
//  MatchMate
//

import Foundation
import SwiftData

/// Composition root. Builds the object graph **once** and hands out view models that share the
/// same repository instance — which is what keeps list and detail consistent.
@MainActor
final class AppEnvironment {

    let repository: ProfileRepository

    init(modelContainer: ModelContainer, config: APIConfig = .live) {
        let monitor = NetworkMonitor()
        let httpClient = URLSessionHTTPClient()
        let remote = RandomUserRemoteDataSource(client: httpClient, config: config)
        let store = ProfileStore(modelContainer: modelContainer)
        self.repository = ProfileRepositoryImpl(
            remote: remote,
            store: store,
            monitor: monitor,
            config: config
        )
    }

    /// Test / preview seam.
    init(repository: ProfileRepository) {
        self.repository = repository
    }

    func makeDiscoverViewModel() -> DiscoverViewModel {
        DiscoverViewModel(repository: repository)
    }

    func makeDetailViewModel(id: String) -> MatchDetailViewModel {
        MatchDetailViewModel(id: id, repository: repository)
    }
}
