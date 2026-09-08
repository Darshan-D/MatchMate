//
//  HTTPClient.swift
//  MatchMate
//

import Foundation
import os

/// Minimal GET-only HTTP client. Generic over the decoded type and independent of any endpoint,
/// so it is trivial to stub in tests via `URLProtocol`.
protocol HTTPClient: Sendable {
    func get<T: Decodable & Sendable>(_ url: URL) async throws -> T
}

/// `URLSession` + `async/await` implementation. Not main-actor isolated — decoding runs off the
/// main thread. Maps transport/status/decoding failures onto `AppError`.
struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .matchMateDefault, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func get<T: Decodable & Sendable>(_ url: URL) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch let urlError as URLError {
            Log.network.warning("Transport error for \(url.absoluteString, privacy: .public): \(urlError.code.rawValue)")
            throw AppError.connectivity
        }

        guard let http = response as? HTTPURLResponse else {
            throw AppError.server(-1)
        }

        switch http.statusCode {
        case 200..<300:
            break
        case 429:
            Log.network.warning("Rate limited (429) for \(url.absoluteString, privacy: .public)")
            throw AppError.rateLimited
        default:
            Log.network.error("HTTP \(http.statusCode) for \(url.absoluteString, privacy: .public)")
            throw AppError.server(http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            Log.network.error("Decoding \(String(describing: T.self), privacy: .public) failed: \(error.localizedDescription)")
            throw AppError.decoding
        }
    }
}

extension URLSession {
    /// Fails fast instead of parking requests when offline — the repository wants a quick failure
    /// so it can fall back to the cache.
    static var matchMateDefault: URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }
}
