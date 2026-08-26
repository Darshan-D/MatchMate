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

    init(id: String,
         firstName: String,
         lastName: String,
         age: Int,
         city: String,
         state: String,
         country: String,
         email: String,
         phone: String,
         nationality: String,
         registeredDate: Date,
         thumbnailURLString: String?,
         largePhotoURLString: String?,
         statusRaw: String,
         pageFetched: Int) {
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
        self.pageFetched = pageFetched
    }
}
