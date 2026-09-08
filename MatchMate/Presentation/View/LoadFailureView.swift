//
//  LoadFailureView.swift
//  MatchMate
//

import SwiftUI

/// Full-screen state for a cold start that produced nothing to show — offline with no cache, or
/// a server/rate-limit failure before the first page landed.
struct LoadFailureView: View {
    let error: AppError
    var onRetry: () -> Void

    private var isOffline: Bool { error == .offlineNoCache }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: isOffline ? "wifi.slash" : "exclamationmark.icloud")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(.pink.opacity(0.8))
                .padding(.bottom, 8)

            Text(isOffline ? "You're Offline" : "Couldn't Load Matches")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)

            Text(error.errorDescription ?? "Something went wrong.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onRetry) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 200)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [.pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Capsule()
                    )
                    .shadow(color: .pink.opacity(0.4), radius: 8, y: 4)
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }
}

#Preview("Offline") {
    LoadFailureView(error: .offlineNoCache, onRetry: {})
}

#Preview("Server error") {
    LoadFailureView(error: .rateLimited, onRetry: {})
}
