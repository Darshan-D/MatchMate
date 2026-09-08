//
//  MatchDetailView.swift
//  MatchMate
//

import SwiftUI
import Kingfisher

@MainActor
struct MatchDetailView: View {
    @State private var viewModel: MatchDetailViewModel

    init(viewModel: MatchDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                if let profile = viewModel.profile {
                    content(for: profile)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 400)
                }
            }
            .ignoresSafeArea(edges: .top)

            if let error = viewModel.error {
                ErrorBannerView(error: error) { viewModel.error = nil }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: viewModel.error)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.profile?.status)
        .task { await viewModel.start() }
    }

    private func content(for profile: Profile) -> some View {
        VStack(spacing: 0) {
            hero(for: profile)

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("\(profile.fullName), \(profile.age)")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.heavy)
                        .multilineTextAlignment(.center)
                    Text("\(profile.city), \(profile.country)")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                infoCards(for: profile)
                actionButtons(for: profile)
            }
            .padding(.horizontal, 24)
            .offset(y: -15)
        }
    }

    private func hero(for profile: Profile) -> some View {
        ZStack(alignment: .bottom) {
            KFImage(profile.largePhotoURL) // picture.large — full-bleed hero
                .placeholder { Color.gray.opacity(0.15).overlay(ProgressView()) }
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 400)
                .clipped()

            LinearGradient(colors: [.clear, Color(.systemBackground)], startPoint: .center, endPoint: .bottom)
                .frame(height: 150)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func infoCards(for profile: Profile) -> some View {
        VStack(spacing: 12) {
            infoRow(icon: "envelope.fill", color: .indigo, text: profile.email)
            infoRow(icon: "phone.fill", color: .green, text: profile.phone)
            infoRow(icon: "flag.fill", color: .blue, text: nationalityName(profile.nationality))
            if let registered = profile.registeredDate {
                infoRow(
                    icon: "calendar.badge.clock",
                    color: .orange,
                    text: "Joined \(registered.formatted(date: .abbreviated, time: .omitted))"
                )
            }
        }
    }

    private func infoRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(text)
                .font(.body)
                .fontWeight(.medium)
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func actionButtons(for profile: Profile) -> some View {
        HStack(spacing: 20) {
            switch profile.status {
            case .accepted:
                Button { Task { await viewModel.decline() } } label: { Image(systemName: "xmark") }
                    .buttonStyle(DetailIconButtonStyle(color: .red, gradient: [.pink, .red]))
                    .accessibilityLabel("Decline")
                Button("Accepted") { Task { await viewModel.accept() } }
                    .buttonStyle(ModernActionButtonStyle(color: .teal, isSelected: true))
                    .accessibilityLabel("Accepted")
            case .declined:
                Button("Declined") { Task { await viewModel.decline() } }
                    .buttonStyle(ModernActionButtonStyle(color: .pink, isSelected: true))
                    .accessibilityLabel("Declined")
                Button { Task { await viewModel.accept() } } label: { Image(systemName: "heart.fill") }
                    .buttonStyle(DetailIconButtonStyle(color: .green, gradient: [.teal, .green]))
                    .accessibilityLabel("Accept")
            case .pending:
                Button("Decline") { Task { await viewModel.decline() } }
                    .buttonStyle(ModernActionButtonStyle(color: .pink, isSelected: false))
                Button("Accept") { Task { await viewModel.accept() } }
                    .buttonStyle(ModernActionButtonStyle(color: .teal, isSelected: false))
            }
        }
        .padding(.top, 10)
    }

    private func nationalityName(_ code: String) -> String {
        Locale.current.localizedString(forRegionCode: code) ?? code
    }
}

#if DEBUG
#Preview {
    let env = AppEnvironment(repository: PreviewProfileRepository())
    let profiles = Profile.previewList()
    return NavigationStack {
        MatchDetailView(viewModel: env.makeDetailViewModel(id: profiles[1].id))
    }
}
#endif
