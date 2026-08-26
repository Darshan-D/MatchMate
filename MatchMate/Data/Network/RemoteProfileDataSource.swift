//
//  RemoteProfileDataSource.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation

protocol RemoteProfileDataSource {
    func fetchPage(_ page: Int, results: Int, seed: String) async throws -> [ProfileDTO]
}
