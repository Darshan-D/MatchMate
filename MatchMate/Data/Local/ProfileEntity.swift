//
//  ProfileEntity.swift
//  MatchMate
//

import Foundation
import SwiftData

/// SwiftData persistence record. Mirrors `Profile` plus the ordering key. Kept internal to the
/// data layer — it never leaves `ProfileStore`.
@Model
final class ProfileEntity {
    @Attribute(.unique) var id: String
    var firstName: String = ""
    var lastName: String = ""
    var age: Int = 0
    var city: String = ""
    var state: String = ""
    var country: String = ""
    var email: String = ""
    var phone: String = ""
    var nationality: String = ""
    var registeredDate: Date?
    var thumbnailURLString: String?
    var largePhotoURLString: String?
    var statusRaw: String = MatchStatus.pending.rawValue
    var sortIndex: Int = 0

    var status: MatchStatus {
        get { MatchStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    init(id: String) {
        self.id = id
    }

    /// Copies every server-owned field from a domain value. Deliberately leaves `status`
    /// untouched — a local Accept/Decline always wins over a re-fetched row.
    func apply(_ profile: Profile) {
        firstName = profile.firstName
        lastName = profile.lastName
        age = profile.age
        city = profile.city
        state = profile.state
        country = profile.country
        email = profile.email
        phone = profile.phone
        nationality = profile.nationality
        registeredDate = profile.registeredDate
        thumbnailURLString = profile.thumbnailURL?.absoluteString
        largePhotoURLString = profile.largePhotoURL?.absoluteString
        sortIndex = profile.sortIndex
    }

    var domain: Profile {
        Profile(
            id: id,
            firstName: firstName,
            lastName: lastName,
            age: age,
            city: city,
            state: state,
            country: country,
            email: email,
            phone: phone,
            nationality: nationality,
            registeredDate: registeredDate,
            thumbnailURL: thumbnailURLString.flatMap(URL.init(string:)),
            largePhotoURL: largePhotoURLString.flatMap(URL.init(string:)),
            sortIndex: sortIndex,
            status: status
        )
    }
}
