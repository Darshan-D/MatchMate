//
//  MatchListView.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import SwiftUI

struct MatchListView: View {
    @Bindable var viewModel: MatchListViewModel
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.profiles) { profile in
                            NavigationLink(value: profile.id) {
                                MatchCardView(profile: profile) {
                                    Task { await viewModel.accept(profile.id) }
                                } onDecline: {
                                    Task { await viewModel.decline(profile.id) }
                                }
                            }
                            .buttonStyle(.plain)
                            .task {
                                // Triggers pagination when near the bottom
                                await viewModel.loadNextPageIfNeeded(currentItem: profile)
                            }
                        }
                    }
                    .padding()
                }

                if viewModel.isLoadingPage && viewModel.profiles.isEmpty {
                    ProgressView("Finding matches...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.isLoadingPage {
                    ProgressView()
                        .padding()
                }

                if let error = viewModel.error {
                    ErrorBannerView(error: error)
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                }
            }
            .navigationTitle("Profile Matches")
            .navigationDestination(for: String.self) { profileId in
                // Use the composition root to build and inject the view model
                MatchDetailView(
                    viewModel: AppComposition.makeMatchDetailViewModel(profileId: profileId, context: context)
                )
            }
            .task {
                await viewModel.loadInitial()
            }
        }
    }
}
