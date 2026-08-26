//
//  LocalProfileDataSource.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation

@MainActor
protocol LocalProfileDataSource {
    func upsert(_ profiles: [Profile], page: Int) throws
    func fetchAll() throws -> [Profile]
    func fetch(id: String) throws -> Profile?
    func updateStatus(id: String, status: MatchStatus) throws
}
