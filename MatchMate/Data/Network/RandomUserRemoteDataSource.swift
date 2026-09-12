//
//  RandomUserRemoteDataSource.swift
//  MatchMate
//

import Foundation
import os

/// Turns a page number into a Random User request. Endpoint-specific; transport and error
/// mapping live in the injected `HTTPClient` (which is the test seam).
struct RandomUserRemoteDataSource: Sendable {
    private let client: HTTPClient
    private let config: APIConfig

    init(client: HTTPClient, config: APIConfig = .live) {
        self.client = client
        self.config = config
    }

    func fetchPage(_ page: Int) async throws -> RandomUserResponse {
        guard var components = URLComponents(url: config.baseURL, resolvingAgainstBaseURL: false) else {
            throw AppError.server(-1)
        }
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "results", value: String(config.resultsPerPage)),
            URLQueryItem(name: "seed", value: config.seed)
        ]
        guard let url = components.url else { throw AppError.server(-1) }

        Log.network.debug("Fetching page \(page)")
        return try await client.get(url)
    }
}
