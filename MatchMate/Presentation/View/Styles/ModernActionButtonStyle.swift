//
//  ModernActionButtonStyle.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import SwiftUI

struct ModernActionButtonStyle: ButtonStyle {
    let color: Color
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.bold))
            // Vibrant text color when selected, neutral gray when unselected
            .foregroundColor(isSelected ? color : .primary.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            // Faint colored background when selected, faint gray when unselected
            .background(isSelected ? color.opacity(0.15) : Color(uiColor: .tertiarySystemFill))
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

