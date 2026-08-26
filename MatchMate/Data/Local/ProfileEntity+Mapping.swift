//
//  ProfileEntity+Mapping.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation
import SwiftData

extension ProfileEntity {
    convenience init(from profile: Profile, page: Int) {
        self.init(
            id: profile.id,
            firstName: profile.firstName,
            lastName: profile.lastName,
            age: profile.age,
            city: profile.city,
            state: profile.state,
            country: profile.country,
            email: profile.email,
            phone: profile.phone,
            nationality: profile.nationality,
            registeredDate: profile.registeredDate,
            thumbnailURLString: profile.thumbnailURL?.absoluteString,
            largePhotoURLString: profile.largePhotoURL?.absoluteString,
            statusRaw: profile.status.rawValue,
            pageFetched: page
        )
    }

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
