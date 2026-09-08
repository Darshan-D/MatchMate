//
//  ProfileRepository.swift
//  MatchMate
//

import Foundation

/// The presentation layer's only window into data.
///
/// The repository owns the canonical in-memory list and publishes it as a broadcast stream, so
/// the list and detail screens observe the *same* source and can never disagree — no manual
/// refresh, no shared view model. All mutations flow back through here.
protocol ProfileRepository: Sendable {

    /// Live view of the full, ordered profile list. Emits the current value on subscription,
    /// then again on every change (page load, status update, refresh). Multiple concurrent
    /// subscribers are supported.
    func profiles() -> AsyncStream<[Profile]>

    /// Live reachability. Emits the current value on subscription, then on every change.
    func connectivity() -> AsyncStream<Bool>

    /// Loads the cache into memory and emits it, then (if online) kicks a silent background
    /// refresh. Fetches page 1 from the network if the cache is empty.
    func bootstrap() async throws

    /// Fetches the next page, merges it (preserving local decisions), persists, and emits.
    /// The pagination cursor is only advanced on success.
    func loadNextPage() async throws

    /// Re-fetches every page loaded so far and merges server-side field changes, keeping local
    /// `status` and ordering intact.
    func refresh() async throws

    /// Applies an Accept/Decline. Emits optimistically, persists, and reverts + re-emits on failure.
    func updateStatus(id: String, to status: MatchStatus) async throws
}
