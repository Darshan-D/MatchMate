//
//  ProfileRepositoryImpl.swift
//  MatchMate
//

import Foundation
import os

/// The single source of truth.
///
/// Holds the canonical profile list in memory and broadcasts it to every subscriber via
/// `AsyncStream`. The list and detail screens both observe `profiles()`, so they are always
/// consistent with zero cross-screen plumbing. SwiftData (`ProfileStore`) is the durable cache
/// behind it; the network is tried first and falls back to cache when offline.
actor ProfileRepositoryImpl: ProfileRepository {

    private let remote: RandomUserRemoteDataSource
    private let store: ProfilePersisting
    private let monitor: NetworkMonitoring
    private let config: APIConfig

    private var current: [Profile] = []
    private var continuations: [UUID: AsyncStream<[Profile]>.Continuation] = [:]
    private var nextPage = 1
    private var isPaging = false
    private var didBootstrap = false

    init(
        remote: RandomUserRemoteDataSource,
        store: ProfilePersisting,
        monitor: NetworkMonitoring,
        config: APIConfig = .live
    ) {
        self.remote = remote
        self.store = store
        self.monitor = monitor
        self.config = config
        Task { await self.observeConnectivity() }
    }

    // MARK: - Streams

    nonisolated func profiles() -> AsyncStream<[Profile]> {
        AsyncStream { continuation in
            let id = UUID()
            Task { await self.addSubscriber(id, continuation) }
            continuation.onTermination = { _ in
                Task { await self.removeSubscriber(id) }
            }
        }
    }

    nonisolated func connectivity() -> AsyncStream<Bool> {
        monitor.updates()
    }

    private func addSubscriber(_ id: UUID, _ continuation: AsyncStream<[Profile]>.Continuation) {
        continuations[id] = continuation
        continuation.yield(current)
    }

    private func removeSubscriber(_ id: UUID) {
        continuations[id] = nil
    }

    private func broadcast() {
        for continuation in continuations.values {
            continuation.yield(current)
        }
    }

    // MARK: - Loading

    func bootstrap() async throws {
        guard !didBootstrap else { return }

        current = (try? await store.fetchAll()) ?? []
        broadcast()
        let servedFromCache = !current.isEmpty

        let highestPage = (try? await store.highestLoadedPage(resultsPerPage: config.resultsPerPage)) ?? 0
        nextPage = highestPage + 1

        if current.isEmpty {
            do {
                try await fetchMergePersist(page: 1)
                nextPage = 2
            } catch AppError.connectivity {
                throw AppError.offlineNoCache
            }
        }

        didBootstrap = true

        // Only worth a silent refresh when we showed the user *stale* cache. A cache we just
        // fetched fresh needs nothing.
        if servedFromCache, monitor.isConnected {
            Task { try? await self.refresh() }
        }
    }

    func loadNextPage() async throws {
        guard !isPaging else { return }
        isPaging = true
        defer { isPaging = false }

        guard monitor.isConnected else {
            throw AppError.endOfCache
        }

        do {
            try await fetchMergePersist(page: nextPage)
            nextPage += 1
        } catch AppError.connectivity where !current.isEmpty {
            throw AppError.endOfCache
        }
    }

    func refresh() async throws {
        guard monitor.isConnected, !isPaging else { return }
        isPaging = true
        defer { isPaging = false }

        let lastLoadedPage = max(nextPage - 1, 1)
        for page in 1...lastLoadedPage {
            try await fetchMergePersist(page: page)
        }
    }

    // MARK: - Mutation

    func updateStatus(id: String, to status: MatchStatus) async throws {
        guard let index = current.firstIndex(where: { $0.id == id }) else { return }
        let previous = current[index].status
        guard previous != status else { return }

        current[index].status = status
        broadcast() // optimistic — both screens update immediately

        do {
            try await store.updateStatus(id: id, to: status)
        } catch {
            current[index].status = previous
            broadcast()
            Log.repository.error("Persisting status failed for \(id, privacy: .public); rolled back")
            throw AppError.persistence
        }
    }

    // MARK: - Internals

    /// Fetch one page, merge it into the in-memory list (preserving local `status`), persist, emit.
    /// Throws `AppError` untranslated — callers decide how to present connectivity failures.
    private func fetchMergePersist(page: Int) async throws {
        let response = try await remote.fetchPage(page)
        let base = (page - 1) * config.resultsPerPage
        let fetched = response.results.enumerated().map { offset, dto in
            dto.toDomain(sortIndex: base + offset)
        }

        do {
            try await store.upsert(fetched)
        } catch {
            Log.persistence.error("upsert failed for page \(page): \(error.localizedDescription)")
            throw AppError.persistence
        }

        current = Self.merge(existing: current, fetched: fetched)
        broadcast()
    }

    private static func merge(existing: [Profile], fetched: [Profile]) -> [Profile] {
        var byID = Dictionary(existing.map { ($0.id, $0) }) { first, _ in first }
        for var incoming in fetched {
            incoming.status = byID[incoming.id]?.status ?? incoming.status // local decision wins
            byID[incoming.id] = incoming
        }
        return byID.values.sorted { $0.sortIndex < $1.sortIndex }
    }

    private func observeConnectivity() async {
        var wasConnected = monitor.isConnected
        for await connected in monitor.updates() {
            if connected, !wasConnected, didBootstrap {
                Task { try? await self.refresh() }
            }
            wasConnected = connected
        }
    }
}
