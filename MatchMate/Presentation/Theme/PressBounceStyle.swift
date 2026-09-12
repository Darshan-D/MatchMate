//
//  PressBounceStyle.swift
//  MatchMate
//

import SwiftUI

/// Shared press feedback: a quick spring scale-down on tap. Used by the deck controls, the
/// detail action bar, and the retry button.
struct PressBounceStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.9

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: configuration.isPressed)
    }
}
