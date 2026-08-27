//
//  MatchDetailViewModel.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation

@Observable
final class MatchDetailViewModel {
    var profile: Profile?
    var error: ProfileRepositoryError?

    private let profileId: String
    private let getProfile: GetProfileUseCase
    private let updateStatus: UpdateMatchStatusUseCase

    init(profileId: String, getProfile: GetProfileUseCase, updateStatus: UpdateMatchStatusUseCase) {
        self.profileId = profileId
        self.getProfile = getProfile
        self.updateStatus = updateStatus
    }

    func loadProfile() async {
        do {
            self.profile = try await getProfile.execute(id: profileId)
            self.error = nil
        } catch {
            self.error = .persistence(error)
        }
    }

    func accept() async {
        await update(status: .accepted)
    }

    func decline() async {
        await update(status: .declined)
    }

    private func update(status: MatchStatus) async {
        guard var currentProfile = profile else { return }
        let oldStatus = currentProfile.status

        // Optimistic UI
        currentProfile.status = status
        self.profile = currentProfile

        do {
            try await updateStatus.execute(id: profileId, status: status)
            self.error = nil
        } catch {
            // Rollback
            currentProfile.status = oldStatus
            self.profile = currentProfile
            self.error = .persistence(error)
        }
    }
}
