//
//  ErrorBannerView.swift
//  MatchMate
//

import SwiftUI

/// Transient toast for a recoverable error. Auto-dismisses; tap to dismiss early.
struct ErrorBannerView: View {
    let error: AppError
    var onDismiss: () -> Void = {}

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.callout.weight(.bold))
            Text(error.errorDescription ?? "Something went wrong.")
                .font(.footnote.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(tint.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: tint.opacity(0.35), radius: 12, y: 6)
        .padding(.horizontal, 16)
        .onTapGesture { onDismiss() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(error.errorDescription ?? "Error"))
        .accessibilityAddTraits(.isButton)
        .task(id: error) {
            try? await Task.sleep(for: .seconds(4))
            onDismiss()
        }
    }

    private var tint: Color {
        switch error {
        case .rateLimited, .endOfCache: return Palette.amber
        case .connectivity: return Palette.slate
        default: return Palette.rose
        }
    }

    private var icon: String {
        switch error {
        case .connectivity, .endOfCache: return "wifi.slash"
        case .rateLimited: return "hourglass"
        default: return "exclamationmark.triangle.fill"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ErrorBannerView(error: .connectivity)
        ErrorBannerView(error: .rateLimited)
        ErrorBannerView(error: .persistence)
    }
}
