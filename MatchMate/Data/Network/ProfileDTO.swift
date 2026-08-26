//
//  ProfileDTA.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation

// MARK: - API Response Wrapper

struct RandomUserResponse: Decodable {
    let results: [ProfileDTO]
}

// MARK: - Profile DTO

struct ProfileDTO: Decodable {
    let login: LoginDTO
    let name: NameDTO
    let dob: DobDTO
    let location: LocationDTO
    let email: String
    let phone: String
    let nat: String
    let registered: RegisteredDTO
    let picture: PictureDTO
}

struct LoginDTO: Decodable { let uuid: String }
struct NameDTO: Decodable { let first: String; let last: String }
struct DobDTO: Decodable { let age: Int }
struct LocationDTO: Decodable { let city: String; let state: String; let country: String }
struct RegisteredDTO: Decodable { let date: String } // Stored as ISO8601 string
struct PictureDTO: Decodable { let large: String; let medium: String }
