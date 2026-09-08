//
//  MatchCardView.swift
//  MatchMate
//

import SwiftUI
import Kingfisher

/// A single match card. The photo/name/location area navigates to the detail screen; the
/// Accept/Decline controls sit in a separate hit region so taps never collide.
struct MatchCardView: View {
    let profile: Profile
    var onAccept: () -> Void
    var onDecline: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            NavigationLink(value: profile.id) {
                infoSection
            }
            .buttonStyle(.plain)

            actionSection
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }

    private var infoSection: some View {
        VStack(spacing: 16) {
            KFImage(profile.thumbnailURL) // picture.medium — right size for a thumbnail
                .placeholder { Color.gray.opacity(0.2).overlay(ProgressView()) }
                .resizable()
                .scaledToFill()
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                .padding(.top, 20)

            VStack(spacing: 6) {
                Text(profile.fullName)
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundStyle(.primary)
                Text("\(profile.age) • \(profile.city), \(profile.state)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profile.fullName), \(profile.age), \(profile.city)")
        .accessibilityHint("Opens full profile")
    }

    @ViewBuilder
    private var actionSection: some View {
        switch profile.status {
        case .pending:
            HStack(spacing: 24) {
                iconButton(icon: "xmark", gradient: [.pink, .red], label: "Decline", action: onDecline)
                iconButton(icon: "heart.fill", gradient: [.teal, .green], label: "Accept", action: onAccept)
            }
        case .accepted:
            statusPill(text: "Accepted", systemImage: "checkmark.circle.fill", tint: .teal)
        case .declined:
            statusPill(text: "Declined", systemImage: "xmark.circle.fill", tint: .pink)
        }
    }

    private func iconButton(icon: String, gradient: [Color], label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
        }
        .buttonStyle(SpringBounceButtonStyle())
        .accessibilityLabel(label)
    }

    private func statusPill(text: String, systemImage: String, tint: Color) -> some View {
        HStack {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.headline)
        .foregroundStyle(tint)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(tint.opacity(0.15), in: Capsule())
        .accessibilityLabel("Status: \(text)")
    }
}

/// Press-bounce for the round icon buttons.
struct SpringBounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ScrollView {
            VStack(spacing: 20) {
                MatchCardView(profile: .preview(status: .pending), onAccept: {}, onDecline: {})
                MatchCardView(profile: .preview(status: .accepted), onAccept: {}, onDecline: {})
                MatchCardView(profile: .preview(status: .declined), onAccept: {}, onDecline: {})
            }
            .padding()
        }
    }
}
#endif
