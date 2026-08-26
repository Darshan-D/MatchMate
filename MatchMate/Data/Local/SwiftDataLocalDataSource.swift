//
//  SwiftDataLocalDataSource.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataLocalDataSource: LocalProfileDataSource {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func upsert(_ profiles: [Profile], page: Int) throws {
        for profile in profiles {
            let id = profile.id
            let descriptor = FetchDescriptor<ProfileEntity>(predicate: #Predicate { $0.id == id })

            if let existing = try context.fetch(descriptor).first {
                existing.firstName = profile.firstName
                existing.lastName = profile.lastName
                existing.age = profile.age
                existing.city = profile.city
                existing.state = profile.state
                existing.country = profile.country
                existing.email = profile.email
                existing.phone = profile.phone
                existing.nationality = profile.nationality
                existing.registeredDate = profile.registeredDate
                existing.thumbnailURLString = profile.thumbnailURL?.absoluteString
                existing.largePhotoURLString = profile.largePhotoURL?.absoluteString
                existing.pageFetched = page

                // Note: We deliberately DO NOT update `status` to preserve local decisions.
            } else {
                // Insert new profile
                let newEntity = ProfileEntity(from: profile, page: page)
                context.insert(newEntity)
            }
        }
        try context.save()
    }

    func fetchAll() throws -> [Profile] {
        let descriptor = FetchDescriptor<ProfileEntity>(sortBy: [SortDescriptor(\.pageFetched)])
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func fetch(id: String) throws -> Profile? {
        let descriptor = FetchDescriptor<ProfileEntity>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first?.toDomain()
    }

    func updateStatus(id: String, status: MatchStatus) throws {
        let descriptor = FetchDescriptor<ProfileEntity>(predicate: #Predicate { $0.id == id })
        if let existing = try context.fetch(descriptor).first {
            existing.status = status
            try context.save()
        }
    }
}
