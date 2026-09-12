//
//  DeckControls.swift
//  MatchMate
//

import SwiftUI

/// The Pass / Undo / Like button row beneath the swipe deck.
struct DeckControls: View {
    var canUndo: Bool
    var enabled: Bool
    var onPass: () -> Void
    var onUndo: () -> Void
    var onLike: () -> Void

    var body: some View {
        HStack(spacing: 26) {
            circle(
                icon: "xmark",
                size: 62,
                fill: AnyShapeStyle(Palette.passGradient),
                shadow: Palette.slate,
                action: onPass
            )
            .accessibilityLabel("Pass")

            circle(
                icon: "arrow.uturn.backward",
                size: 48,
                fill: AnyShapeStyle(Color(.systemBackground)),
                tint: Palette.amber,
                border: Palette.amber.opacity(0.5),
                shadow: Palette.amber,
                action: onUndo
            )
            .disabled(!canUndo)
            .opacity(canUndo ? 1 : 0.35)
            .accessibilityLabel("Undo last decision")

            circle(
                icon: "heart.fill",
                size: 62,
                fill: AnyShapeStyle(Palette.likeGradient),
                shadow: Palette.emerald,
                action: onLike
            )
            .accessibilityLabel("Like")
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
    }

    private func circle(
        icon: String,
        size: CGFloat,
        fill: AnyShapeStyle,
        tint: Color = .white,
        border: Color = .white.opacity(0.25),
        shadow: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.impact(size > 55 ? .medium : .light)
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(fill, in: Circle())
                .overlay(Circle().strokeBorder(border, lineWidth: 1.5))
                .shadow(color: shadow.opacity(0.45), radius: 12, y: 6)
        }
        .buttonStyle(PressBounceStyle(pressedScale: 0.88))
    }
}

#Preview {
    DeckControls(canUndo: true, enabled: true, onPass: {}, onUndo: {}, onLike: {})
        .padding()
}
