//
//  MatchListView.swift
//  MatchMate
//

import SwiftUI

@MainActor
struct MatchListView: View {
    @State private var viewModel: MatchListViewModel
    private let environment: AppEnvironment

    init(viewModel: MatchListViewModel, environment: AppEnvironment) {
        _viewModel = State(initialValue: viewModel)
        self.environment = environment
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                background

                content

                if let error = viewModel.error, viewModel.loadFailure == nil {
                    ErrorBannerView(error: error) { viewModel.error = nil }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .animation(.spring(duration: 0.35), value: viewModel.error)
            .navigationTitle("Discover")
            .navigationDestination(for: String.self) { id in
                MatchDetailView(viewModel: environment.makeDetailViewModel(id: id))
            }
            .task { await viewModel.start() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let failure = viewModel.loadFailure {
            LoadFailureView(error: failure) { Task { await viewModel.retry() } }
        } else if viewModel.isLoadingInitial && viewModel.profiles.isEmpty {
            ProgressView("Finding matches…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                if viewModel.isOffline { offlineBar }
                profileList
            }
        }
    }

    private var profileList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.profiles) { profile in
                    MatchCardView(
                        profile: profile,
                        onAccept: { Task { await viewModel.accept(profile.id) } },
                        onDecline: { Task { await viewModel.decline(profile.id) } }
                    )
                    .task { await viewModel.loadMoreIfNeeded(currentItem: profile) }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .refreshable { await viewModel.refresh() }
    }

    private var offlineBar: some View {
        Label("You're offline — showing saved profiles", systemImage: "wifi.slash")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.gray)
            .accessibilityLabel("Offline. Showing saved profiles.")
    }

    private var background: some View {
        LinearGradient(
            colors: [.yellow.opacity(0.15), .yellow.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#if DEBUG
#Preview("Populated") {
    let env = AppEnvironment(repository: PreviewProfileRepository())
    return MatchListView(viewModel: env.makeListViewModel(), environment: env)
}

#Preview("Cold offline") {
    let env = AppEnvironment(repository: PreviewProfileRepository(profiles: [], bootstrapError: .offlineNoCache))
    return MatchListView(viewModel: env.makeListViewModel(), environment: env)
}
#endif
