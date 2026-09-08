//
//  ErrorBannerView.swift
//  MatchMate
//

import SwiftUI

/// Transient error banner. Shows the `AppError`'s user-facing message and dismisses itself.
struct ErrorBannerView: View {
    let error: AppError
    var onDismiss: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
            Text(error.errorDescription ?? "Something went wrong.")
                .font(.subheadline)
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(error.errorDescription ?? "Error"))
        .task(id: error) {
            try? await Task.sleep(for: .seconds(4))
            onDismiss()
        }
    }
}
