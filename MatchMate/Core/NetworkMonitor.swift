//
//  NetworkMonitor.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Network
import Observation

@Observable
final class NetworkMonitor: Reachable {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")

    // Default to true; updates as soon as the monitor starts.
    var isConnected: Bool = true

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
