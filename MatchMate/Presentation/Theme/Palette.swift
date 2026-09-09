//
//  Palette.swift
//  MatchMate
//

import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

/// The app's visual language. Brand hues are fixed; surfaces use system semantic colors so the
/// UI adapts to light and dark automatically.
enum Palette {
    static let rose = Color(hex: 0xE35D74)
    static let peach = Color(hex: 0xF0A93B)
    static let emerald = Color(hex: 0x1FA97B)
    static let slate = Color(hex: 0x7C7F8A)
    static let amber = Color(hex: 0xF0A93B)
    static let plum = Color(hex: 0x5E2E50)

    /// Primary call-to-action / accent gradient.
    static let brand = LinearGradient(
        colors: [rose, peach],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let likeGradient = LinearGradient(
        colors: [emerald, Color(hex: 0x63C9A4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let passGradient = LinearGradient(
        colors: [Color(hex: 0x9AA0A6), Color(hex: 0x6B7076)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Warm ambient background behind every screen.
    static func canvas(_ scheme: ColorScheme) -> LinearGradient {
        let stops: [Color] = scheme == .dark
            ? [Color(hex: 0x1A1114), Color(hex: 0x120E13)]
            : [Color(hex: 0xFDF6F3), Color(hex: 0xF7ECEC)]
        return LinearGradient(colors: stops, startPoint: .top, endPoint: .bottom)
    }

    static func tint(for status: MatchStatus) -> Color {
        switch status {
        case .accepted: return emerald
        case .declined: return rose
        case .pending: return slate
        }
    }
}

extension MatchStatus {
    var label: String {
        switch self {
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        case .pending: return "Pending"
        }
    }

    var symbol: String {
        switch self {
        case .accepted: return "heart.fill"
        case .declined: return "xmark"
        case .pending: return "clock"
        }
    }
}
