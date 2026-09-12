//
//  Profile.swift
//  MatchMate
//

import Foundation

/// The pure domain model. Deliberately not a SwiftData `@Model` so the domain and presentation
/// layers stay free of persistence concerns, and so it can cross actor boundaries (`Sendable`).
struct Profile: Identifiable, Equatable, Sendable {
    /// Stable id — maps to `login.uuid` from the API.
    let id: String
    let firstName: String
    let lastName: String
    let age: Int
    let city: String
    let state: String
    let country: String
    let email: String
    let phone: String
    /// ISO 3166-1 alpha-2 country code (the API's `nat` field).
    let nationality: String
    /// `nil` when the API value couldn't be parsed — the UI omits the row rather than showing a wrong date.
    let registeredDate: Date?
    /// `picture.medium` — used for list thumbnails.
    let thumbnailURL: URL?
    /// `picture.large` — used for the detail hero image.
    let largePhotoURL: URL?
    /// Deterministic ordering key: `(page - 1) * resultsPerPage + indexInPage`.
    /// Keeps the list in API order and stable across re-fetches.
    let sortIndex: Int
    var status: MatchStatus

    var fullName: String { "\(firstName) \(lastName)" }
}
