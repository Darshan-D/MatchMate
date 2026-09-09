//
//  LoadFailureView.swift
//  MatchMate
//

import SwiftUI

/// Full-screen state for a cold start that produced nothing — offline with no cache, or a
/// server/rate-limit failure before the first page landed.
struct LoadFailureView: View {
    let error: AppError
    var onRetry: () -> Void

    private var isOffline: Bool { error == .offlineNoCache }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Palette.brand.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: isOffline ? "wifi.slash" : "exclamationmark.icloud")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Palette.rose)
            }

            Text(isOffline ? "You're Offline" : "Couldn't Load Matches")
                .font(.system(.title, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)

            Text(error.errorDescription ?? "Something went wrong.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Button(action: onRetry) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 200)
                    .padding(.vertical, 15)
                    .background(Palette.brand, in: Capsule())
                    .shadow(color: Palette.rose.opacity(0.4), radius: 10, y: 5)
            }
            .buttonStyle(PressBounceStyle())
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }
}

#Preview("Offline") { LoadFailureView(error: .offlineNoCache, onRetry: {}) }
#Preview("Server") { LoadFailureView(error: .rateLimited, onRetry: {}) }
