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

                        // Dynamic Action Buttons
                        HStack(spacing: 20) {
                            if profile.status == .accepted {
                                // Shrink 'Decline' to a small "X" on the left
                                Button {
                                    Task { await viewModel.decline() }
                                } label: {
                                    Image(systemName: "xmark")
                                }
                                .buttonStyle(DetailIconButtonStyle(color: .red, gradient: [.pink, .red]))

                                // Expand 'Accept' to fill the rest
                                Button("Accepted") {
                                    Task { await viewModel.accept() }
                                }
                                .buttonStyle(ModernActionButtonStyle(color: .teal, isSelected: true))

                            } else if profile.status == .declined {
                                // Expand 'Decline' to fill the rest
                                Button("Declined") {
                                    Task { await viewModel.decline() }
                                }
                                .buttonStyle(ModernActionButtonStyle(color: .pink, isSelected: true))

                                // Shrink 'Accept' to a small "heart" on the right
                                Button {
                                    Task { await viewModel.accept() }
                                } label: {
                                    Image(systemName: "heart.fill")
                                }
                                .buttonStyle(DetailIconButtonStyle(color: .green, gradient: [.teal, .green]))

                            } else {
                                // Pending state: both buttons share space equally
                                Button("Decline") { Task { await viewModel.decline() } }
                                    .buttonStyle(ModernActionButtonStyle(color: .pink, isSelected: false))

                                Button("Accept") { Task { await viewModel.accept() } }
                                    .buttonStyle(ModernActionButtonStyle(color: .teal, isSelected: false))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        // This animates the layout transition smoothly when the status changes
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: profile.status)
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
