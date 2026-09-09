//
//  DecisionsView.swift
//  MatchMate
//

import SwiftUI
import Kingfisher

/// The reviewable list of every profile you've decided on. Shares the Discover screen's view
/// model, so a change here shows up there instantly (and vice versa). Swipe a row to flip a
/// decision; tap to open the full profile.
@MainActor
struct DecisionsView: View {
    let viewModel: MatchListViewModel
    let environment: AppEnvironment
    @Environment(\.colorScheme) private var scheme
    @State private var filter: Filter = .all

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All", accepted = "Liked", declined = "Passed"
        var id: Self { self }
    }

    private var rows: [Profile] {
        switch filter {
        case .all: return viewModel.decided
        case .accepted: return viewModel.decided.filter { $0.status == .accepted }
        case .declined: return viewModel.decided.filter { $0.status == .declined }
        }
    }

    var body: some View {
        ZStack {
            Palette.canvas(scheme).ignoresSafeArea()

            VStack(spacing: 12) {
                Picker("Filter", selection: $filter) {
                    ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                if rows.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
        }
        .navigationTitle("Your Decisions")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: filter) { Haptics.selection() }
    }

    private var list: some View {
        List {
            ForEach(rows) { profile in
                ZStack {
                    NavigationLink(value: DiscoverView.Route.detail(profile.id)) { EmptyView() }
                        .opacity(0)
                    DecisionRow(profile: profile)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        Task { await viewModel.accept(profile.id) }
                    } label: { Label("Like", systemImage: "heart.fill") }
                    .tint(Palette.emerald)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        Task { await viewModel.decline(profile.id) }
                    } label: { Label("Pass", systemImage: "xmark") }
                    .tint(Palette.rose)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)
            Text(filter == .all ? "No decisions yet" : "Nothing here")
                .font(.headline)
            Text("Swipe on the Discover screen to build your list.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private struct DecisionRow: View {
    let profile: Profile

    var body: some View {
        HStack(spacing: 14) {
            KFImage(profile.thumbnailURL)
                .resizable()
                .placeholder { Color.gray.opacity(0.2) }
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(profile.fullName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(profile.age) · \(profile.city)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            StatusBadge(status: profile.status, compact: true)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        .contentShape(Rectangle())
    }
}

#if DEBUG
#Preview {
    let env = AppEnvironment(repository: PreviewProfileRepository())
    return NavigationStack {
        DecisionsView(viewModel: env.makeListViewModel(), environment: env)
    }
}
#endif
