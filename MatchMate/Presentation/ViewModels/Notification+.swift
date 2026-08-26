//
//  Notification+.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation

extension Notification.Name {
    // Custom notification to broadcast status changes across the app
    static let matchStatusDidUpdate = Notification.Name("matchStatusDidUpdate")
}
