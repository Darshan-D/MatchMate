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
        Text(errorMessage)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.9))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom, 8)
    }
}
