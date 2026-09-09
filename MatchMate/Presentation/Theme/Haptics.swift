//
//  Haptics.swift
//  MatchMate
//

import UIKit

/// Thin wrapper over `UIFeedbackGenerator` for the swipe deck and action buttons.
@MainActor
enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
