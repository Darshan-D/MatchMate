//
//  RandomUserRemoteDataSource.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation

@MainActor
final class RandomUserRemoteDataSource: RemoteProfileDataSource {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchPage(_ page: Int, results: Int, seed: String) async throws -> [ProfileDTO] {
        var components = URLComponents(string: "https://randomuser.me/api/")!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "results", value: String(results)),
            URLQueryItem(name: "seed", value: seed)
        ]

        guard let url = components.url else {
            print("❌ [ERROR][RandomUserRemoteDataSource] Remote error: Invalid URL components.")
            throw URLError(.badURL)
        }

        do {
            let (data, _) = try await session.data(from: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(RandomUserResponse.self, from: data)

            print("✅ [SUCCESS][RandomUserRemoteDataSource] Remote success: Fetched and decoded page \(page) (\(response.results.count) results).")
            return response.results

        } catch let error as URLError {
            print("⚠️ [WARN][RandomUserRemoteDataSource] Remote network error on page \(page): \(error.localizedDescription)")
            throw ProfileRepositoryError.network(error)
        } catch {
            print("❌ [ERROR][RandomUserRemoteDataSource] Remote decoding error on page \(page): \(error)")
            throw ProfileRepositoryError.decoding(error)
        }
    }
}
