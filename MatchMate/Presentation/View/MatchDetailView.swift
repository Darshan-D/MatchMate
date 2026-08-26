//
//  MatchDetailView.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import SwiftUI
import Kingfisher

struct MatchDetailView: View {
    @State var viewModel: MatchDetailViewModel

    var body: some View {
        ScrollView {
            if let profile = viewModel.profile {
                VStack(spacing: 0) {
                    // Hero Image with Gradient Fade
                    ZStack(alignment: .bottom) {
                        KFImage(profile.largePhotoURL)
                            .placeholder { ProgressView() }
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 400)
                            .clipped()

                        LinearGradient(
                            colors: [.clear, Color(.systemBackground)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                        .frame(height: 150)
                    }

                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("\(profile.firstName) \(profile.lastName), \(profile.age)")
                                .font(.system(.largeTitle, design: .rounded))
                                .fontWeight(.heavy)

                            Text("\(profile.city), \(profile.country)")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }

                        // Modern Info Cards
                        VStack(spacing: 12) {
                            detailRow(icon: "envelope.fill", color: .indigo, text: profile.email)
                            detailRow(icon: "phone.fill", color: .green, text: profile.phone)
                            detailRow(icon: "calendar.badge.clock", color: .orange, text: "Joined \(profile.registeredDate.formatted(date: .abbreviated, time: .omitted))")
                        }
                        .padding(.horizontal)

                        // Preserved Async Actions
                        HStack(spacing: 20) {
                            Button(profile.status == .declined ? "Declined" : "Decline") {
                                Task { await viewModel.decline() }
                            }
                            .buttonStyle(ModernActionButtonStyle(color: .red, isSelected: profile.status == .declined))

                            Button(profile.status == .accepted ? "Accepted" : "Accept") {
                                Task { await viewModel.accept() }
                            }
                            .buttonStyle(ModernActionButtonStyle(color: .green, isSelected: profile.status == .accepted))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                    }
                    .offset(y: -15) // Pull content up into the gradient fade
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea(edges: .top)
        .task {
            await viewModel.loadProfile()
        }
    }

    private func detailRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(text)
                .font(.body)
                .fontWeight(.medium)
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

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
