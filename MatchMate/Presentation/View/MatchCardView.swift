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
        VStack(spacing: 16) {
            // Preserved KFImage for offline caching
            KFImage(profile.largePhotoURL)
                .placeholder {
                    Color.gray.opacity(0.2)
                        .overlay(ProgressView())
                }
                .resizable()
                .scaledToFill()
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                .padding(.top, 20)

            VStack(spacing: 6) {
                Text("\(profile.firstName) \(profile.lastName)")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(.primary)

                Text("\(profile.age) • \(profile.city), \(profile.state)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 24) {
                if profile.status == .pending {
                    actionButton(icon: "xmark", color: .red, gradient: [.pink, .red], action: onDecline)
                    actionButton(icon: "heart.fill", color: .green, gradient: [.teal, .green], action: onAccept)
                } else {
                    statusPill(for: profile.status)
                }
            }
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }

    private func actionButton(icon: String, color: Color, gradient: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(SpringBounceButtonStyle())
    }

    @ViewBuilder
    private func statusPill(for status: MatchStatus) -> some View {
        let isAccepted = status == .accepted
        HStack {
            Image(systemName: isAccepted ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(isAccepted ? "Accepted" : "Declined")
        }
        .font(.headline)
        .foregroundColor(isAccepted ? .teal : .pink)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(isAccepted ? Color.teal.opacity(0.15) : Color.pink.opacity(0.15))
        .clipShape(Capsule())
    }
}

// Custom animation style for card buttons
struct SpringBounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
