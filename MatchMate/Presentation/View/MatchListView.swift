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
                LinearGradient(
                    colors: [Color.yellow.opacity(0.15), Color.yellow.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if viewModel.profiles.isEmpty && viewModel.error != nil {
                    OfflineEmptyStateView {
                        Task { await viewModel.loadInitial() }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
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
                                    // Strictly preserved pagination trigger
                                    await viewModel.loadNextPageIfNeeded(currentItem: profile)
                                }
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        // Guarantees list and detail never disagree
                        Task { await viewModel.refreshFromCache() }
                    }

                    if let error = viewModel.error {
                        ErrorBannerView(error: error)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.spring(), value: viewModel.error != nil)
                            .zIndex(1)
                    }
                }

                if viewModel.isLoadingPage && viewModel.profiles.isEmpty {
                    ProgressView("Finding matches...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.isLoadingPage {
                    ProgressView()
                        .padding()
                        .background(Material.ultraThin)
                        .clipShape(Capsule())
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.automatic, for: .navigationBar)
            .navigationDestination(for: String.self) { profileId in
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
