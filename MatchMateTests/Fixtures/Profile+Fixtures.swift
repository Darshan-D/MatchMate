//
//  Profile+Fixtures.swift
//  MatchMateTests
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
        state: String = "England",
        country: String = "United Kingdom",
        email: String = "john.doe@example.com",
        phone: String = "555-0199",
        nationality: String = "GB",
        registeredDate: Date? = Date(timeIntervalSince1970: 1_400_000_000),
        thumbnailURL: URL? = URL(string: "https://example.com/medium.jpg"),
        largePhotoURL: URL? = URL(string: "https://example.com/large.jpg"),
        sortIndex: Int = 0,
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
            sortIndex: sortIndex,
            status: status
        )
    }

    /// A contiguous page of stubs with sequential ids and sort indices.
    static func page(_ page: Int, perPage: Int = 10, status: MatchStatus = .pending) -> [Profile] {
        let base = (page - 1) * perPage
        return (0..<perPage).map { offset in
            .stub(id: "\(base + offset)", firstName: "User\(base + offset)", sortIndex: base + offset, status: status)
        }
    }
}
