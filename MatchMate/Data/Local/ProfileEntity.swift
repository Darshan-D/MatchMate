//
//  ProfileEntity.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation
import SwiftData

@Model
final class ProfileEntity {
    @Attribute(.unique) var id: String // login.uuid
    var firstName: String
    var lastName: String
    var age: Int
    var city: String
    var state: String
    var country: String
    var email: String
    var phone: String
    var nationality: String
    var registeredDate: Date
    var thumbnailURLString: String?
    var largePhotoURLString: String?
    var statusRaw: String
    var pageFetched: Int

    // Computed property bridging the primitive string to the Domain enum
    var status: MatchStatus {
        get { MatchStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    init(from profile: Profile, page: Int) {
        self.id = profile.id
        self.firstName = profile.firstName
        self.lastName = profile.lastName
        self.age = profile.age
        self.city = profile.city
        self.state = profile.state
        self.country = profile.country
        self.email = profile.email
        self.phone = profile.phone
        self.nationality = profile.nationality
        self.registeredDate = profile.registeredDate
        self.thumbnailURLString = profile.thumbnailURL?.absoluteString
        self.largePhotoURLString = profile.largePhotoURL?.absoluteString
        self.statusRaw = profile.status.rawValue
        self.pageFetched = page
    }

    // Maps Entity back to Domain
    func toDomain() -> Profile {
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
            thumbnailURL: thumbnailURLString.flatMap { URL(string: $0) },
            largePhotoURL: largePhotoURLString.flatMap { URL(string: $0) },
            status: status
        )
    }
}
