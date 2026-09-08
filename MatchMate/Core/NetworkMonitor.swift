//
//  NetworkMonitor.swift
//  MatchMate
//

import Foundation
import Network
import os

/// Observes reachability so the repository can skip doomed requests and the UI can show an
/// offline banner. Abstracted behind a protocol so it can be faked in tests.
protocol NetworkMonitoring: Sendable {
    /// Current best-effort reachability. Safe to read from any isolation.
    var isConnected: Bool { get }
    /// Emits the current value immediately, then every time reachability flips.
    func updates() -> AsyncStream<Bool>
}

/// `NWPathMonitor`-backed implementation.
///
/// Mutable state (the flag + subscriber continuations) is guarded by an unfair lock; the
/// `NWPathMonitor` itself is only touched from `init`/`deinit` and its callback queue, hence
/// `@unchecked Sendable`.
final class NetworkMonitor: NetworkMonitoring, @unchecked Sendable {

    private struct State {
        var isConnected = true
        var continuations: [UUID: AsyncStream<Bool>.Continuation] = [:]
    }

    private let state = OSAllocatedUnfairLock(initialState: State())
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "MatchMate.NetworkMonitor")

    init(startImmediately: Bool = true) {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handle(path.status == .satisfied)
        }
        if startImmediately {
            monitor.start(queue: queue)
        }
    }

    deinit {
        monitor.cancel()
        state.withLock { s in
            s.continuations.values.forEach { $0.finish() }
            s.continuations.removeAll()
        }
    }

    var isConnected: Bool {
        state.withLock { $0.isConnected }
    }

    func updates() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let id = UUID()
            let current = state.withLock { s -> Bool in
                s.continuations[id] = continuation
                return s.isConnected
            }
            continuation.yield(current)
            continuation.onTermination = { [weak self] _ in
                self?.state.withLock { $0.continuations[id] = nil }
            }
        }
    }

    private func handle(_ connected: Bool) {
        let continuations = state.withLock { s -> [AsyncStream<Bool>.Continuation] in
            guard s.isConnected != connected else { return [] }
            s.isConnected = connected
            return Array(s.continuations.values)
        }
        guard !continuations.isEmpty else { return }
        Log.network.info("Connectivity changed: \(connected ? "online" : "offline", privacy: .public)")
        for continuation in continuations {
            continuation.yield(connected)
        }
    }
}
