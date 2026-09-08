//
//  MatchStatus.swift
//  MatchMate
//

import Foundation

enum MatchStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case accepted
    case declined
}
