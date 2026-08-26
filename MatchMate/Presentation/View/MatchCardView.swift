//
//  MatchCardView.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import SwiftUI
import Kingfisher

struct MatchCardView: View {
    let profile: Profile
    var onAccept: () -> Void
    var onDecline: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // STRICT REQUIREMENT: Using KFImage for guaranteed offline disk caching
            KFImage(profile.largePhotoURL)
                .placeholder {
                    Color.gray.opacity(0.3)
                        .overlay(ProgressView())
                }
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: 150)
                .clipShape(Circle())
                .padding(.top, 16)

            VStack(spacing: 4) {
                Text("\(profile.firstName) \(profile.lastName)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("\(profile.age), \(profile.city)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(profile.state)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 40) {
                if profile.status == .pending {
                    actionButton(icon: "xmark", color: .red, action: onDecline)
                    actionButton(icon: "checkmark", color: .green, action: onAccept)
                } else {
                    statusPill(for: profile.status)
                }
            }
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private func actionButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2.weight(.bold))
                .foregroundColor(color)
                .padding()
                .background(Circle().stroke(color, lineWidth: 2))
        }
    }

    @ViewBuilder
    private func statusPill(for status: MatchStatus) -> some View {
        let isAccepted = status == .accepted
        Text(isAccepted ? "Accepted" : "Declined")
            .font(.headline)
            .foregroundColor(isAccepted ? .white : .gray)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(isAccepted ? Color.green : Color.gray.opacity(0.2))
            .clipShape(Capsule())
    }
}
