//
//  MatchDetailView.swift
//  MatchMate
//

import SwiftUI
import Kingfisher

@MainActor
struct MatchDetailView: View {
    @State private var viewModel: MatchDetailViewModel
    @Environment(\.colorScheme) private var scheme

    init(viewModel: MatchDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            Palette.canvas(scheme).ignoresSafeArea()

            if let profile = viewModel.profile {
                content(for: profile)
            } else {
                ProgressView().controlSize(.large)
            }

            if let error = viewModel.error {
                VStack {
                    Spacer()
                    ErrorBannerView(error: error) { viewModel.error = nil }
                        .padding(.bottom, 90)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: viewModel.error)
        .animation(.spring(response: 0.4, dampingFraction: 0.72), value: viewModel.profile?.status)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.start() }
    }

    // MARK: - Content

    private func content(for profile: Profile) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                hero(for: profile)
                infoSheet(for: profile)
            }
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .safeAreaInset(edge: .bottom) { actionBar(for: profile) }
    }

    private func hero(for profile: Profile) -> some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let stretch = max(minY, 0)

            ZStack(alignment: .bottom) {
                KFImage(profile.largePhotoURL)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: 420 + stretch)
                    .blur(radius: 22)
                    .overlay(.black.opacity(0.28))
                    .offset(y: -stretch)

                LinearGradient(
                    colors: [.clear, .black.opacity(0.15), .black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 260)

                VStack(spacing: 14) {
                    KFImage(profile.largePhotoURL)
                        .resizable()
                        .placeholder {
                            Image(systemName: "person.fill").font(.system(size: 60))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .scaledToFill()
                        .frame(width: 150, height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .strokeBorder(.white.opacity(0.7), lineWidth: 4))
                        .shadow(color: .black.opacity(0.3), radius: 16, y: 8)

                    VStack(spacing: 4) {
                        Text("\(profile.fullName), \(profile.age)")
                            .font(.system(.title, design: .rounded).weight(.bold))
                        Text("\(profile.city), \(profile.country)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                    if profile.status != .pending {
                        StatusBadge(status: profile.status)
                            .colorScheme(.light)
                    }
                }
                .padding(.bottom, 34)
            }
        }
        .frame(height: 420)
    }

    private func infoSheet(for profile: Profile) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Capsule()
                .fill(.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            chips(for: profile)

            VStack(alignment: .leading, spacing: 12) {
                Text("Details")
                    .font(.headline)
                infoRow(icon: "envelope.fill", tint: Palette.plum, text: profile.email)
                infoRow(icon: "phone.fill", tint: Palette.emerald, text: profile.phone)
                if let registered = profile.registeredDate {
                    infoRow(
                        icon: "calendar",
                        tint: Palette.amber,
                        text: "Joined \(registered.formatted(date: .abbreviated, time: .omitted))"
                    )
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .offset(y: -28)
    }

    private func chips(for profile: Profile) -> some View {
        HStack(spacing: 10) {
            chip(icon: "birthday.cake", text: "\(profile.age)")
            chip(icon: "mappin.circle.fill", text: profile.state)
            chip(text: "\(flag(profile.nationality)) \(nationalityName(profile.nationality))")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(icon: String? = nil, text: String) -> some View {
        HStack(spacing: 5) {
            if let icon { Image(systemName: icon) }
            Text(text).lineLimit(1)
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(Palette.plum)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Palette.plum.opacity(0.1), in: Capsule())
    }

    private func infoRow(icon: String, tint: Color, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            Text(text)
                .font(.callout.weight(.medium))
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Action bar

    private func actionBar(for profile: Profile) -> some View {
        HStack(spacing: 14) {
            decisionButton(
                title: "Pass",
                symbol: "xmark",
                active: profile.status == .declined,
                activeStyle: AnyShapeStyle(Palette.passGradient),
                action: { Task { await viewModel.decline() } }
            )
            decisionButton(
                title: "Like",
                symbol: "heart.fill",
                active: profile.status == .accepted,
                activeStyle: AnyShapeStyle(Palette.likeGradient),
                action: { Task { await viewModel.accept() } }
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .background(.ultraThinMaterial)
    }

    private func decisionButton(
        title: String,
        symbol: String,
        active: Bool,
        activeStyle: AnyShapeStyle,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.impact(.medium)
            action()
        } label: {
            Label(active ? "\(title)ed" : title, systemImage: symbol)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(active ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                .background {
                    if active {
                        Capsule().fill(activeStyle)
                    } else {
                        Capsule().fill(Color(.tertiarySystemFill))
                    }
                }
        }
        .buttonStyle(PressBounceStyle())
        .accessibilityLabel(active ? "\(title)ed" : title)
    }

    // MARK: - Helpers

    private func nationalityName(_ code: String) -> String {
        Locale.current.localizedString(forRegionCode: code) ?? code
    }

    private func flag(_ code: String) -> String {
        code.uppercased().unicodeScalars.reduce(into: "") { result, scalar in
            if let flagScalar = UnicodeScalar(127_397 + scalar.value) {
                result.unicodeScalars.append(flagScalar)
            }
        }
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
