//
//  ProfileDTOMappingTests.swift
//  MatchMateTests
//

import XCTest
@testable import MatchMate

final class ProfileDTOMappingTests: XCTestCase {

    private func decode(_ json: String) throws -> ProfileDTO {
        try JSONDecoder().decode(RandomUserResponse.self, from: Data(json.utf8)).results[0]
    }

    private func envelope(registered: String, nat: String = "de") -> String {
        """
        { "results": [{
          "login": { "uuid": "abc-123" },
          "name": { "first": "Adilson", "last": "Pultrum" },
          "dob": { "age": 56 },
          "location": { "city": "Oudega", "state": "Drenthe", "country": "Netherlands" },
          "email": "adilson@example.com",
          "phone": "0611-1234567",
          "nat": "\(nat)",
          "registered": { "date": "\(registered)" },
          "picture": { "large": "https://example.com/l.jpg", "medium": "https://example.com/m.jpg" }
        }] }
        """
    }

    func test_toDomain_mapsCoreFields() throws {
        let dto = try decode(envelope(registered: "2005-04-17T22:26:14.782Z"))
        let profile = dto.toDomain(sortIndex: 4)

        XCTAssertEqual(profile.id, "abc-123")
        XCTAssertEqual(profile.fullName, "Adilson Pultrum")
        XCTAssertEqual(profile.age, 56)
        XCTAssertEqual(profile.nationality, "DE")
        XCTAssertEqual(profile.sortIndex, 4)
        XCTAssertEqual(profile.status, .pending)
        XCTAssertEqual(profile.thumbnailURL?.absoluteString, "https://example.com/m.jpg")
        XCTAssertEqual(profile.largePhotoURL?.absoluteString, "https://example.com/l.jpg")
    }

    func test_registeredDate_parsesFractionalSeconds() throws {
        let dto = try decode(envelope(registered: "2005-04-17T22:26:14.782Z"))
        XCTAssertNotNil(dto.toDomain(sortIndex: 0).registeredDate)
    }

    func test_registeredDate_parsesPlainISO8601() throws {
        let dto = try decode(envelope(registered: "2005-04-17T22:26:14Z"))
        XCTAssertNotNil(dto.toDomain(sortIndex: 0).registeredDate)
    }

    func test_registeredDate_garbage_isNilNotToday() throws {
        let dto = try decode(envelope(registered: "not-a-date"))
        XCTAssertNil(dto.toDomain(sortIndex: 0).registeredDate)
    }
}
