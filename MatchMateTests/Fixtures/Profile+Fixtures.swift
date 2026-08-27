//
//  Profile+Fixtures.swift
//  MatchMateTests
//
//  Created by Darshan Dodia on 27/08/26.
//

import Foundation
@testable import MatchMate

extension Profile {
    static func stub(
        id: String = "1",
        firstName: String = "John",
        lastName: String = "Doe",
        age: Int = 30,
        city: String = "London",
        state: String = "ENG",
        country: String = "UK",
        email: String = "john.doe@test.com",
        phone: String = "555-0199",
        nationality: String = "GB",
        registeredDate: Date = Date(),
        thumbnailURL: URL? = nil,
        largePhotoURL: URL? = nil,
        status: MatchStatus = .pending
    ) -> Profile {
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
            thumbnailURL: thumbnailURL,
            largePhotoURL: largePhotoURL,
            status: status
        )
    }
}
