//
//  Profile.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation

/// The pure Domain model. This is intentionally NOT a SwiftData @Model to preserve the Clean Architecture boundary.
struct Profile: Identifiable, Equatable {
    let id: String // Mapped to login.uuid
    let firstName: String
    let lastName: String
    let age: Int
    let city: String
    let state: String
    let country: String
    let email: String
    let phone: String
    let nationality: String
    let registeredDate: Date
    let thumbnailURL: URL?
    let largePhotoURL: URL?
    var status: MatchStatus
}
