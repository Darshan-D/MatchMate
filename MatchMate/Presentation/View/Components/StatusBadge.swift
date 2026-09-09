//
//  StatusBadge.swift
//  MatchMate
//

import SwiftUI

/// Pill showing a profile's decision. Used on decision rows and the detail header.
struct StatusBadge: View {
    let status: MatchStatus
    var compact = false

    var body: some View {
        let tint = Palette.tint(for: status)
        return Label(status.label, systemImage: status.symbol)
            .font(compact ? .caption2.weight(.bold) : .footnote.weight(.bold))
            .foregroundStyle(tint)
            .padding(.horizontal, compact ? 8 : 12)
            .padding(.vertical, compact ? 4 : 7)
            .background(tint.opacity(0.14), in: Capsule())
            .overlay(Capsule().strokeBorder(tint.opacity(0.25), lineWidth: 1))
            .accessibilityLabel(status.label)
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusBadge(status: .accepted)
        StatusBadge(status: .declined)
        StatusBadge(status: .pending, compact: true)
    }
    .padding()
}
