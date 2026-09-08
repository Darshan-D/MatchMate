//
//  MatchDetailViewModel.swift
//  MatchMate
//

import Foundation
import Observation

@MainActor
@Observable
final class MatchDetailViewModel {

    private(set) var profile: Profile?
    var error: AppError?

    private let id: String
    private let repository: ProfileRepository
    private var started = false

    init(id: String, repository: ProfileRepository) {
        self.id = id
        self.repository = repository
    }

    /// Entry point for the view's `.task`. Consumes the shared profile stream for the lifetime of
    /// the screen, so any status change — here or on the list — flows straight back in and the two
    /// screens never disagree. Ends when the task is cancelled (the view goes away).
    func start() async {
        guard !started else { return }
        started = true
        for await list in repository.profiles() {
            profile = list.first { $0.id == id }
        }
    }

    func accept() async { await setStatus(.accepted) }
    func decline() async { await setStatus(.declined) }

    private func setStatus(_ status: MatchStatus) async {
        do {
            try await repository.updateStatus(id: id, to: status)
            error = nil
        } catch {
            self.error = (error as? AppError) ?? .persistence
        }
    }
}
