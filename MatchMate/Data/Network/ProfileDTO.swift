//
//  ProfileDTO.swift
//  MatchMate
//

import Foundation

// MARK: - Wire format

struct RandomUserResponse: Decodable, Sendable {
    let results: [ProfileDTO]
}

struct ProfileDTO: Decodable, Sendable {
    let login: Login
    let name: Name
    let dob: Dob
    let location: Location
    let email: String
    let phone: String
    let nat: String
    let registered: Registered
    let picture: Picture

    struct Login: Decodable, Sendable { let uuid: String }
    struct Name: Decodable, Sendable { let first: String; let last: String }
    struct Dob: Decodable, Sendable { let age: Int }
    struct Location: Decodable, Sendable { let city: String; let state: String; let country: String }
    struct Registered: Decodable, Sendable { let date: String }
    struct Picture: Decodable, Sendable { let large: String; let medium: String }
}

// MARK: - Mapping

extension ProfileDTO {
    /// - Parameter sortIndex: deterministic ordering key assigned by the repository.
    func toDomain(sortIndex: Int) -> Profile {
        Profile(
            id: login.uuid,
            firstName: name.first,
            lastName: name.last,
            age: dob.age,
            city: location.city,
            state: location.state,
            country: location.country,
            email: email,
            phone: phone,
            nationality: nat.uppercased(),
            registeredDate: RegisteredDateParser.date(from: registered.date),
            thumbnailURL: URL(string: picture.medium),
            largePhotoURL: URL(string: picture.large),
            sortIndex: sortIndex,
            status: .pending
        )
    }
}

/// Random User returns ISO-8601 with fractional seconds (`2005-04-17T22:26:14.782Z`), but we
/// tolerate the plain form too. On failure we return `nil` rather than substituting `Date()`,
/// which would silently persist wrong data.
enum RegisteredDateParser {
    private static let withFractionalSeconds: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let plain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func date(from string: String) -> Date? {
        withFractionalSeconds.date(from: string) ?? plain.date(from: string)
    }
}
