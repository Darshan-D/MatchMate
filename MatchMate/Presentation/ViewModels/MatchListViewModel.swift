//
//  MatchListViewModel.swift
//  MatchMate
//

import Foundation
import Observation

@MainActor
@Observable
final class MatchListViewModel {

    private(set) var profiles: [Profile] = []
    private(set) var isLoadingInitial = false
    private(set) var isLoadingMore = false
    private(set) var isOffline = false
    var error: AppError?

    /// Non-nil when the first load produced nothing to show — drives the full-screen retry state.
    var loadFailure: AppError? {
        guard profiles.isEmpty, !isLoadingInitial, let error else { return nil }
        return error
    }

    private let repository: ProfileRepository
    private var started = false

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    /// Entry point for the view's `.task`. Runs for the lifetime of the screen: it kicks the
    /// initial load and then keeps consuming the repository's streams until the task is
    /// cancelled (i.e. the view goes away).
    func start() async {
        guard !started else { return }
        started = true

        async let streaming: Void = consumeStreams()
        await runBootstrap()
        await streaming
    }

    func retry() async {
        await runBootstrap()
    }

    func loadMoreIfNeeded(currentItem: Profile) async {
        guard !isLoadingMore, currentItem.id == profiles.last?.id else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        await run { try await repository.loadNextPage() }
    }

    func refresh() async {
        await run { try await repository.refresh() }
    }

    func accept(_ id: String) async { await run { try await repository.updateStatus(id: id, to: .accepted) } }
    func decline(_ id: String) async { await run { try await repository.updateStatus(id: id, to: .declined) } }

    // MARK: - Internals

    private func runBootstrap() async {
        isLoadingInitial = profiles.isEmpty
        await run { try await repository.bootstrap() }
        isLoadingInitial = false
    }

    private func consumeStreams() async {
        async let profileUpdates: Void = observeProfiles()
        async let connectivityUpdates: Void = observeConnectivity()
        _ = await (profileUpdates, connectivityUpdates)
    }

    private func observeProfiles() async {
        for await list in repository.profiles() {
            profiles = list
            if !list.isEmpty { isLoadingInitial = false }
        }
    }

    private func observeConnectivity() async {
        for await connected in repository.connectivity() {
            isOffline = !connected
        }
    }

    private func run(_ operation: () async throws -> Void) async {
        do {
            try await operation()
            error = nil
        } catch {
            self.error = (error as? AppError) ?? .persistence
        }
    }
}
