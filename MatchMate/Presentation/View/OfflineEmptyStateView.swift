//
//  OfflineEmptyStateView.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import SwiftUI

struct OfflineEmptyStateView: View {
    var onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 72, weight: .light))
                .foregroundColor(.pink.opacity(0.8))
                .padding(.bottom, 8)

            Text("You're Offline")
                .font(.largeTitle)
                .fontWeight(.heavy)

            Text("We couldn't find any offline profiles. Please check your internet connection and try again.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onRetry) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [.pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Capsule())
                    .shadow(color: .pink.opacity(0.4), radius: 8, y: 4)
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
