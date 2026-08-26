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
    private let updateStatus: UpdateMatchStatusUseCase
    private let repository: ProfileRepository

    private var currentPage: Int = 1
    private var hasMorePages: Bool = true

    init(fetchProfiles: FetchProfilesUseCase, updateStatus: UpdateMatchStatusUseCase, repository: ProfileRepository) {
        self.fetchProfiles = fetchProfiles
        self.updateStatus = updateStatus
        self.repository = repository
    }

    func loadInitial() async {
        guard profiles.isEmpty else { return }

        isLoadingPage = true
        error = nil
        currentPage = 1      // Reset to page 1
        hasMorePages = true  // Resurrect pagination if it died offline

        do {
            profiles = try await fetchProfiles.execute(page: currentPage)
        } catch let err as ProfileRepositoryError {
            self.error = err
            await refreshFromCache() // Fallback to offline cache
        } catch {
            self.error = .persistence(error)
        }

        isLoadingPage = false
    }

    func loadNextPageIfNeeded(currentItem: Profile) async {
        guard !isLoadingPage, hasMorePages, let lastItem = profiles.last, currentItem.id == lastItem.id else { return }

        isLoadingPage = true
        currentPage += 1
        do {
            profiles = try await fetchProfiles.execute(page: currentPage)
        } catch ProfileRepositoryError.offlineNoMoreData {
            hasMorePages = false
            self.error = .offlineNoMoreData
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
            // Success: ModelContext.didSaveNotification will fire and ensure sync
        } catch {
            // 4. Rollback on failure
            profiles[index].status = oldStatus
            self.error = .persistence(error)
        }
    }

    @MainActor
    internal func refreshFromCache() async {
        do {
            let cached = try await repository.cachedProfiles()
            // Only update if there's a difference to avoid unnecessary UI redraws
            if self.profiles != cached {
                self.profiles = cached
            }
        } catch {
            print("Failed to sync from local cache: \(error)")
        }
    }
}
