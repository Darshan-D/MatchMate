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
    var firstName: String
    var lastName: String
    var age: Int
    var city: String
    var state: String
    var country: String
    var email: String
    var phone: String
    var nationality: String
    var registeredDate: Date?
    var thumbnailURLString: String?
    var largePhotoURLString: String?
    var statusRaw: String
    var sortIndex: Int

    var status: MatchStatus {
        get { MatchStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: String,
        firstName: String,
        lastName: String,
        age: Int,
        city: String,
        state: String,
        country: String,
        email: String,
        phone: String,
        nationality: String,
        registeredDate: Date?,
        thumbnailURLString: String?,
        largePhotoURLString: String?,
        statusRaw: String,
        sortIndex: Int
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
        self.city = city
        self.state = state
        self.country = country
        self.email = email
        self.phone = phone
        self.nationality = nationality
        self.registeredDate = registeredDate
        self.thumbnailURLString = thumbnailURLString
        self.largePhotoURLString = largePhotoURLString
        self.statusRaw = statusRaw
        self.sortIndex = sortIndex
    }
}
