//
//  MockNetworkMonitor.swift
//  MatchMateTests
//

import Foundation
@testable import MatchMate

/// Reachability stub with a manually-driven stream.
final class MockNetworkMonitor: NetworkMonitoring, @unchecked Sendable {
    private let lock = NSLock()
    private var _connected: Bool
    private var continuations: [UUID: AsyncStream<Bool>.Continuation] = [:]

    init(connected: Bool = true) {
        _connected = connected
    }

    var isConnected: Bool {
        lock.withLock { _connected }
    }

    func updates() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let id = UUID()
            let current: Bool = lock.withLock {
                continuations[id] = continuation
                return _connected
            }
            continuation.yield(current)
            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock { _ = self?.continuations.removeValue(forKey: id) }
            }
        }
    }

    func set(connected: Bool) {
        let toNotify: [AsyncStream<Bool>.Continuation] = lock.withLock {
            _connected = connected
            return Array(continuations.values)
        }
        for continuation in toNotify { continuation.yield(connected) }
    }
}
