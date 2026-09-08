//
//  APIConfig.swift
//  MatchMate
//

import Foundation

/// Injected network configuration — keeps the base URL, seed, and page size out of the
/// data-source and repository code so tests can point at stubs.
struct APIConfig: Sendable {
    var baseURL: URL
    /// Fixed seed so paginated results stay stable (assignment requirement).
    var seed: String
    var resultsPerPage: Int

    static let live = APIConfig(
        baseURL: URL(string: "https://randomuser.me/api/")!,
        seed: "matchmate",
        resultsPerPage: 10
    )
}
