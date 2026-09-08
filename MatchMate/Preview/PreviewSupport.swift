//
//  PreviewSupport.swift
//  MatchMate
//
//  Debug-only fixtures for SwiftUI previews. Excluded from release builds.
//

#if DEBUG
import Foundation

extension Profile {
    static func preview(
        id: String = UUID().uuidString,
        firstName: String = "Florence",
        lastName: String = "Gagné",
        age: Int = 43,
        city: String = "Keswick",
        state: String = "Yukon",
        country: String = "Canada",
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
            email: "\(firstName.lowercased()).\(lastName.lowercased())@example.com",
            phone: "555-0142",
            nationality: "CA",
            registeredDate: Date(timeIntervalSince1970: 1_400_000_000),
            thumbnailURL: nil,
            largePhotoURL: nil,
            sortIndex: sortIndex,
            status: status
        )
    }

    static func previewList(count: Int = 6) -> [Profile] {
        (0..<count).map {
            .preview(
                firstName: ["Florence", "Maxime", "Nilton", "Adilson", "Ena", "Lena"][$0 % 6],
                lastName: ["Gagné", "Smith", "da Luz", "Pultrum", "Ala", "Roy"][$0 % 6],
                age: 30 + $0,
                sortIndex: $0,
                status: [.pending, .accepted, .declined][$0 % 3]
            )
        }
    }
}

/// In-memory repository that drives a real `AsyncStream`, so previews exercise the same
/// observation path as production.
actor PreviewProfileRepository: ProfileRepository {
    private var current: [Profile]
    private let bootstrapError: AppError?
    private var continuations: [UUID: AsyncStream<[Profile]>.Continuation] = [:]

    init(profiles: [Profile] = Profile.previewList(), bootstrapError: AppError? = nil) {
        self.current = profiles
        self.bootstrapError = bootstrapError
    }

    nonisolated func profiles() -> AsyncStream<[Profile]> {
        AsyncStream { continuation in
            let id = UUID()
            Task { await self.register(id, continuation) }
            continuation.onTermination = { _ in Task { await self.unregister(id) } }
        }
    }

    nonisolated func connectivity() -> AsyncStream<Bool> {
        AsyncStream { $0.yield(true) }
    }

    private func register(_ id: UUID, _ c: AsyncStream<[Profile]>.Continuation) {
        continuations[id] = c
        c.yield(current)
    }
    private func unregister(_ id: UUID) { continuations[id] = nil }
    private func emit() { continuations.values.forEach { $0.yield(current) } }

    func bootstrap() async throws {
        if let bootstrapError { throw bootstrapError }
        emit()
    }
    func loadNextPage() async throws {}
    func refresh() async throws {}

    func updateStatus(id: String, to status: MatchStatus) async throws {
        guard let i = current.firstIndex(where: { $0.id == id }) else { return }
        current[i].status = status
        emit()
    }
}
#endif
