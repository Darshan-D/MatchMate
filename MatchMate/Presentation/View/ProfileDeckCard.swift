//
//  ProfileDeckCard.swift
//  MatchMate
//

import SwiftUI

/// A single card in the swipe deck. Purely presentational — drag handling lives in `SwipeDeck`,
/// which also dictates the exact size.
struct ProfileDeckCard: View {
    let profile: Profile
    var size: CGSize
    /// -1 (full drag left / "pass") … 0 (centred) … 1 (full drag right / "like").
    var dragProgress: CGFloat = 0

    var body: some View {
        ZStack {
            RemotePhoto(url: profile.largePhotoURL, foreground: min(size.width * 0.72, 280), cornerRadius: 30)

            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.5), .black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                stampRow
                Spacer()
                caption
            }
            .padding(22)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 24, y: 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(profile.fullName), \(profile.age), \(profile.city). Double-tap for full profile.")
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(profile.fullName)
                .font(.system(.title, design: .rounded).weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 6) {
                Text("\(profile.age)")
                Text("·")
                Text("\(profile.city), \(profile.country)").lineLimit(1)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white.opacity(0.9))

            Label("Tap for full profile", systemImage: "hand.tap.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .padding(.top, 2)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stampRow: some View {
        let liking = dragProgress > 0
        let magnitude = min(abs(dragProgress) / 0.6, 1)
        return HStack {
            if !liking { Spacer() }
            Text(liking ? "LIKE" : "PASS")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(liking ? Palette.emerald : Palette.rose)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(liking ? Palette.emerald : Palette.rose, lineWidth: 4)
                )
                .rotationEffect(.degrees(liking ? -12 : 12))
            if liking { Spacer() }
        }
        .opacity(magnitude)
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview {
    ProfileDeckCard(profile: .preview(), size: CGSize(width: 320, height: 470), dragProgress: 0.5)
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.canvas(.light))
}
#endif
