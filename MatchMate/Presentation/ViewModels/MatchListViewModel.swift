//
//  MatchListViewModel.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import Foundation
import Observation

@Observable
final class MatchListViewModel {
    var profiles: [Profile] = []
    var isLoadingPage: Bool = false
    var error: ProfileRepositoryError?

    private let fetchProfiles: FetchProfilesUseCase
    private let getCachedProfiles: GetCachedProfilesUseCase
    private let updateStatus: UpdateMatchStatusUseCase
    private let getResumePage: GetResumePageUseCase


    private var currentPage: Int = 1

    init(fetchProfiles: FetchProfilesUseCase,
         getCachedProfiles: GetCachedProfilesUseCase,
         updateStatus: UpdateMatchStatusUseCase,
         getResumePage: GetResumePageUseCase) {
        self.fetchProfiles = fetchProfiles
        self.getCachedProfiles = getCachedProfiles
        self.updateStatus = updateStatus
        self.getResumePage = getResumePage
    }

    func loadInitial() async {
        guard profiles.isEmpty else { return }
        isLoadingPage = true
        error = nil

        do {
            let cached = try await getCachedProfiles.execute()

            if cached.isEmpty {
                // True first launch — nothing on disk, must go to network.
                currentPage = 1
                profiles = try await fetchProfiles.execute(page: currentPage)
            } else {
                // Cache is the source of truth — show it immediately, no network needed.
                profiles = cached
                currentPage = try await getResumePage.execute()
            }
        } catch let err as ProfileRepositoryError {
            self.error = err
            if profiles.isEmpty { await refreshFromCache() }
        } catch {
            self.error = .persistence(error)
        }

        isLoadingPage = false
    }

    func loadNextPageIfNeeded(currentItem: Profile) async {
        guard !isLoadingPage, let lastItem = profiles.last, currentItem.id == lastItem.id else { return }

        isLoadingPage = true
        currentPage += 1
        do {
            profiles = try await fetchProfiles.execute(page: currentPage)
            self.error = nil
        } catch ProfileRepositoryError.offlineNoMoreData {
            self.error = .offlineNoMoreData
            currentPage -= 1
        } catch let err as ProfileRepositoryError {
            self.error = err
            currentPage -= 1 // Revert page increment on failure
        } catch {
            self.error = .persistence(error)
        }
        isLoadingPage = false
    }

    func accept(_ id: String) async {
        await optimisticallyUpdateStatus(id: id, newStatus: .accepted)
    }

    func decline(_ id: String) async {
        await optimisticallyUpdateStatus(id: id, newStatus: .declined)
    }

    private func optimisticallyUpdateStatus(id: String, newStatus: MatchStatus) async {
        // 1. Find target and its old status for potential rollback
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        let oldStatus = profiles[index].status

        // 2. Optimistic UI update (instant feedback)
        profiles[index].status = newStatus

        // 3. Persist to SwiftData
        do {
            try await updateStatus.execute(id: id, status: newStatus)
            self.error = nil
        } catch {
            // 4. Rollback on failure
            profiles[index].status = oldStatus
            self.error = .persistence(error)
        }
    }

    @MainActor
    internal func refreshFromCache() async {
        do {
            let cached = try await getCachedProfiles.execute()
            // Only update if there's a difference to avoid unnecessary UI redraws
            if self.profiles != cached {
                self.profiles = cached
            }
        } catch {
            print("❌ [ERROR][MatchListViewModel] Failed to sync from local cache: \(error)")
        }
    }
}
