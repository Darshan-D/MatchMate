//
//  Reachable.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation

/// Protocol allowing us to mock network connectivity in our view model tests.
public protocol Reachable {
    var isConnected: Bool { get }
}
