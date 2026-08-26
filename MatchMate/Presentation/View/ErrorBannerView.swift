//
//  ErrorBannerView.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import SwiftUI

struct ErrorBannerView: View {
    let error: ProfileRepositoryError

    var errorMessage: String {
        switch error {
        case .network(_): return "Network connection failed. Showing offline data."
        case .decoding(_): return "Failed to process profile data."
        case .persistence(_): return "Failed to save data locally."
        case .offlineNoMoreData: return "You're offline. No more cached profiles."
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)

            Text(errorMessage)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(Capsule())
        .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
