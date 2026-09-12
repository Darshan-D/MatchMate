//
//  DiscoverView.swift
//  MatchMate
//

import SwiftUI

/// Navigation targets within the Discover flow.
enum Route: Hashable {
    case detail(String)
    case decisions
}

@MainActor
struct DiscoverView: View {
    @State private var viewModel: DiscoverViewModel
    @State private var path = NavigationPath()
    @State private var command: SwipeDecision?
    @Environment(\.colorScheme) private var scheme
    private let environment: AppEnvironment

    init(viewModel: DiscoverViewModel, environment: AppEnvironment) {
        _viewModel = State(initialValue: viewModel)
        self.environment = environment
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .top) {
                Palette.canvas(scheme).ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    if viewModel.isOffline { offlineBar }
                    stage
                }
                .frame(maxWidth: .infinity)

                if let error = viewModel.error, viewModel.loadFailure == nil {
                    ErrorBannerView(error: error) { viewModel.error = nil }
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.35), value: viewModel.error)
            .animation(.snappy, value: viewModel.isOffline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .detail(let id):
                    MatchDetailView(viewModel: environment.makeDetailViewModel(id: id))
                case .decisions:
                    DecisionsView(viewModel: viewModel)
                }
            }
            .task { await viewModel.start() }
            .task(id: viewModel.deck.first?.id) { await viewModel.loadMoreIfNeeded() }
        }
        .tint(Palette.rose)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MatchMate")
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .foregroundStyle(Palette.brand)
                Text("Find your person")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Haptics.selection()
                path.append(Route.decisions)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.stack.fill")
                    Text("\(viewModel.acceptedCount + viewModel.declinedCount)")
                        .contentTransition(.numericText())
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Palette.plum)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Palette.plum.opacity(0.15), lineWidth: 1))
            }
            .accessibilityLabel("Your decisions")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var offlineBar: some View {
        Label("Offline — showing saved profiles", systemImage: "wifi.slash")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(Palette.slate)
            .accessibilityLabel("Offline. Showing saved profiles.")
    }

    // MARK: - Stage

    @ViewBuilder
    private var stage: some View {
        if let failure = viewModel.loadFailure {
            LoadFailureView(error: failure) { Task { await viewModel.retry() } }
        } else if viewModel.isLoadingInitial && viewModel.profiles.isEmpty {
            loading
        } else if viewModel.deck.isEmpty {
            DeckEmptyView(
                exhausted: viewModel.deckExhausted,
                accepted: viewModel.acceptedCount,
                onRefresh: { await viewModel.refresh() },
                onSeeDecisions: { path.append(Route.decisions) }
            )
        } else {
            deck
        }
    }

    private var deck: some View {
        VStack(spacing: 10) {
            SwipeDeck(
                profiles: viewModel.deck,
                command: $command,
                onDecision: { profile, decision in
                    Task {
                        switch decision {
                        case .like: await viewModel.accept(profile.id)
                        case .pass: await viewModel.decline(profile.id)
                        }
                    }
                },
                onTap: { profile in path.append(Route.detail(profile.id)) }
            )
            .padding(.horizontal, 24)
            .layoutPriority(1)

            DeckControls(
                canUndo: viewModel.canUndo,
                enabled: !viewModel.deck.isEmpty,
                onPass: { command = .pass },
                onUndo: { Task { await viewModel.undo() } },
                onLike: { command = .like }
            )
            .padding(.bottom, 10)
        }
        .padding(.top, 8)
    }

    private var loading: some View {
        VStack(spacing: 16) {
            ProgressView().controlSize(.large)
            Text("Finding matches…")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Shown when there's no one left to review.
private struct DeckEmptyView: View {
    let exhausted: Bool
    let accepted: Int
    let onRefresh: () async -> Void
    let onSeeDecisions: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: exhausted ? "checkmark.seal.fill" : "sparkles")
                .font(.system(size: 58, weight: .light))
                .foregroundStyle(Palette.brand)

            Text(exhausted ? "You're all caught up" : "Loading more matches…")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)

            Text(exhausted
                 ? "You've reviewed everyone we have for now. You liked \(accepted)."
                 : "Hang tight while we bring in more profiles.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if exhausted {
                HStack(spacing: 12) {
                    Button("See decisions", action: onSeeDecisions)
                        .buttonStyle(.borderedProminent)
                        .tint(Palette.rose)
                    Button("Check again") { Task { await onRefresh() } }
                        .buttonStyle(.bordered)
                        .tint(Palette.plum)
                }
                .padding(.top, 4)
            } else {
                ProgressView().padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#if DEBUG
#Preview("Deck") {
    let env = AppEnvironment(repository: PreviewProfileRepository())
    return DiscoverView(viewModel: env.makeDiscoverViewModel(), environment: env)
}

#Preview("Cold offline") {
    let env = AppEnvironment(repository: PreviewProfileRepository(profiles: [], bootstrapError: .offlineNoCache))
    return DiscoverView(viewModel: env.makeDiscoverViewModel(), environment: env)
}
#endif
