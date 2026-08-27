//
//  ProfileDTO+Mapping.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation

extension ProfileDTO {
    func toDomain() -> Profile {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let parsedDate: Date
        if let validDate = formatter.date(from: self.registered.date) {
            parsedDate = validDate
        } else {
            print("⚠️ [WARN][ProfileDTO] Data Drift Warning: Failed to parse registered date string '\(self.registered.date)'. Defaulting to current date.")
            parsedDate = Date()
        }

        return Profile(
            id: self.login.uuid,
            firstName: self.name.first,
            lastName: self.name.last,
            age: self.dob.age,
            city: self.location.city,
            state: self.location.state,
            country: self.location.country,
            email: self.email,
            phone: self.phone,
            nationality: self.nat,
            registeredDate: parsedDate,
            thumbnailURL: URL(string: self.picture.medium),
            largePhotoURL: URL(string: self.picture.large),
            status: .pending
        )
    }
}
