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
    private(set) var reachedEndOfCache = false
    var error: AppError?

    private let repository: ProfileRepository
    private var started = false
    /// The most recent decision, so it can be undone.
    private var lastDecisionID: String?
    /// A just-undone profile, floated back to the front of the deck.
    private var resurfacedID: String?

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    // MARK: - Derived state

    /// Profiles still awaiting a decision — the swipe deck's queue. A just-undone card floats
    /// back to the front so "undo" actually returns you to that person.
    var deck: [Profile] {
        var pending = profiles.filter { $0.status == .pending }
        if let resurfacedID, let index = pending.firstIndex(where: { $0.id == resurfacedID }) {
            pending.insert(pending.remove(at: index), at: 0)
        }
        return pending
    }

    var decided: [Profile] {
        profiles.filter { $0.status != .pending }.sorted { $0.sortIndex > $1.sortIndex }
    }

    var acceptedCount: Int { profiles.lazy.filter { $0.status == .accepted }.count }
    var declinedCount: Int { profiles.lazy.filter { $0.status == .declined }.count }
    var canUndo: Bool { lastDecisionID != nil }

    /// Non-nil when the first load produced nothing to show — drives the full-screen retry state.
    var loadFailure: AppError? {
        guard profiles.isEmpty, !isLoadingInitial, let error else { return nil }
        return error
    }

    /// True once the deck is empty and there is genuinely nothing more to fetch.
    var deckExhausted: Bool {
        deck.isEmpty && !profiles.isEmpty && (reachedEndOfCache || isOffline)
    }

    // MARK: - Lifecycle

    /// Entry point for the view's `.task`. Kicks the initial load, then consumes the repository's
    /// streams until the task is cancelled (the view goes away).
    func start() async {
        guard !started else { return }
        started = true
        async let streaming: Void = consumeStreams()
        await runBootstrap()
        await streaming
    }

    func retry() async {
        reachedEndOfCache = false
        await runBootstrap()
    }

    func refresh() async {
        reachedEndOfCache = false
        await run { try await repository.refresh() }
    }

    // MARK: - Pagination

    /// Called as the deck is consumed. Fetches the next page while the pile is running low.
    func loadMoreIfNeeded() async {
        guard !isLoadingMore, !reachedEndOfCache, deck.count <= 4 else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            try await repository.loadNextPage()
            error = nil
        } catch AppError.endOfCache {
            reachedEndOfCache = true
            error = .endOfCache
        } catch {
            self.error = (error as? AppError) ?? .persistence
        }
    }

    // MARK: - Decisions

    func accept(_ id: String) async { await decide(id, .accepted) }
    func decline(_ id: String) async { await decide(id, .declined) }

    func undo() async {
        guard let id = lastDecisionID else { return }
        lastDecisionID = nil
        await run { try await repository.updateStatus(id: id, to: .pending) }
        resurfacedID = id
    }

    private func decide(_ id: String, _ status: MatchStatus) async {
        resurfacedID = nil
        await run { try await repository.updateStatus(id: id, to: status) }
        if error == nil { lastDecisionID = id }
    }

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
            if connected { reachedEndOfCache = false }
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
