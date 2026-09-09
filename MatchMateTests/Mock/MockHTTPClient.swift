//
//  MockHTTPClient.swift
//  MatchMateTests
//

import Foundation
@testable import MatchMate

/// Returns canned JSON (or errors) per requested `page` query value.
final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    var responsesByPage: [String: Result<Data, AppError>] = [:]
    var defaultResult: Result<Data, AppError> = .failure(.connectivity)

    func get<T>(_ url: URL) async throws -> T where T: Decodable & Sendable {
        let page = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "page" }?.value ?? ""
        let result = responsesByPage[page] ?? defaultResult
        switch result {
        case .success(let data):
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw AppError.decoding
            }
        case .failure(let error):
            throw error
        }
    }
}

enum RandomUserJSON {
    /// Builds a minimally-valid Random User payload with `count` results.
    static func page(count: Int, idPrefix: String = "id") -> Data {
        let users = (0..<count).map { i in
            """
            {
              "login": { "uuid": "\(idPrefix)-\(i)" },
              "name": { "first": "First\(i)", "last": "Last\(i)" },
              "dob": { "age": \(25 + i) },
              "location": { "city": "City\(i)", "state": "State\(i)", "country": "Country\(i)" },
              "email": "user\(i)@example.com",
              "phone": "555-000\(i)",
              "nat": "US",
              "registered": { "date": "2015-05-1\(i % 10)T10:00:00.482Z" },
              "picture": {
                "large": "https://example.com/\(i)-large.jpg",
                "medium": "https://example.com/\(i)-medium.jpg"
              }
            }
            """
        }
        return Data("{ \"results\": [\(users.joined(separator: ","))] }".utf8)
    }
}
