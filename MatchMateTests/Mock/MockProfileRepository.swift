//
//  MockProfileRepository.swift
//  MatchMateTests
//

import Foundation
@testable import MatchMate

/// In-memory `ProfileRepository` that drives real `AsyncStream`s, so view-model tests exercise
/// the same observation path as production.
actor MockProfileRepository: ProfileRepository {

    // Controllable behaviour
    var pages: [Int: [Profile]] = [:]
    var bootstrapError: AppError?
    var nextPageError: AppError?
    var updateStatusError: AppError?
    private(set) var connected = true

    // Call recording
    private(set) var loadNextPageCallCount = 0
    private(set) var refreshCallCount = 0
    private(set) var statusUpdates: [(id: String, status: MatchStatus)] = []

    private var current: [Profile] = []
    private var servedPages: Set<Int> = []
    private var profileContinuations: [UUID: AsyncStream<[Profile]>.Continuation] = [:]
    private var connectivityContinuations: [UUID: AsyncStream<Bool>.Continuation] = [:]

    init(seed: [Profile] = [], pagesAlreadyLoaded: Int = 0) {
        current = seed.sorted { $0.sortIndex < $1.sortIndex }
        if pagesAlreadyLoaded > 0 { servedPages = Set(1...pagesAlreadyLoaded) }
    }

    // MARK: ProfileRepository

    nonisolated func profiles() -> AsyncStream<[Profile]> {
        AsyncStream { continuation in
            let id = UUID()
            Task { await self.addProfileSubscriber(id, continuation) }
            continuation.onTermination = { _ in Task { await self.removeProfileSubscriber(id) } }
        }
    }

    nonisolated func connectivity() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let id = UUID()
            Task { await self.addConnectivitySubscriber(id, continuation) }
            continuation.onTermination = { _ in Task { await self.removeConnectivitySubscriber(id) } }
        }
    }

    func bootstrap() async throws {
        if let bootstrapError { throw bootstrapError }
        if current.isEmpty, let first = pages[1] {
            current = first.sorted { $0.sortIndex < $1.sortIndex }
            servedPages.insert(1)
        }
        emitProfiles()
    }

    func loadNextPage() async throws {
        loadNextPageCallCount += 1
        if let nextPageError { throw nextPageError }
        let candidate = pages.keys.filter { !servedPages.contains($0) }.min()
        guard let candidate, let page = pages[candidate] else { throw AppError.endOfCache }
        servedPages.insert(candidate)
        current = mergeSorted(current, page)
        emitProfiles()
    }

    func refresh() async throws {
        refreshCallCount += 1
        emitProfiles()
    }

    func updateStatus(id: String, to status: MatchStatus) async throws {
        statusUpdates.append((id, status))
        guard let index = current.firstIndex(where: { $0.id == id }) else {
            if let updateStatusError { throw updateStatusError }
            return
        }
        let previous = current[index].status
        current[index].status = status
        emitProfiles() // optimistic

        if let updateStatusError {
            current[index].status = previous
            emitProfiles() // rollback — mirrors ProfileRepositoryImpl
            throw updateStatusError
        }
    }

    // MARK: Test controls

    func seed(_ profiles: [Profile], pagesAlreadyLoaded: Int = 0) {
        current = profiles.sorted { $0.sortIndex < $1.sortIndex }
        if pagesAlreadyLoaded > 0 { servedPages.formUnion(1...pagesAlreadyLoaded) }
        emitProfiles()
    }

    func setPages(_ pages: [Int: [Profile]]) { self.pages = pages }
    func setBootstrapError(_ error: AppError?) { bootstrapError = error }
    func setNextPageError(_ error: AppError?) { nextPageError = error }
    func setUpdateStatusError(_ error: AppError?) { updateStatusError = error }

    func setConnected(_ value: Bool) {
        connected = value
        for continuation in connectivityContinuations.values { continuation.yield(value) }
    }

    // MARK: Internals

    private func addProfileSubscriber(_ id: UUID, _ c: AsyncStream<[Profile]>.Continuation) {
        profileContinuations[id] = c
        c.yield(current)
    }
    private func removeProfileSubscriber(_ id: UUID) { profileContinuations[id] = nil }

    private func addConnectivitySubscriber(_ id: UUID, _ c: AsyncStream<Bool>.Continuation) {
        connectivityContinuations[id] = c
        c.yield(connected)
    }
    private func removeConnectivitySubscriber(_ id: UUID) { connectivityContinuations[id] = nil }

    private func emitProfiles() {
        for continuation in profileContinuations.values { continuation.yield(current) }
    }

    private func mergeSorted(_ existing: [Profile], _ incoming: [Profile]) -> [Profile] {
        var byID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        for var item in incoming {
            if let old = byID[item.id] { item.status = old.status }
            byID[item.id] = item
        }
        return byID.values.sorted { $0.sortIndex < $1.sortIndex }
    }
}
