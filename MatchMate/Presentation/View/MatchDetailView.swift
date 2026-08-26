//
//  MatchDetailView.swift
//  MatchMate
//
//  Created by Darshan Dodia on 26/08/26.
//

import SwiftUI
import Kingfisher

struct MatchDetailView: View {
    // Injected via composition root/factory in actual app
    @State var viewModel: MatchDetailViewModel

    var body: some View {
        ScrollView {
            if let profile = viewModel.profile {
                VStack(spacing: 24) {
                    KFImage(profile.largePhotoURL)
                        .placeholder { ProgressView() }
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 350)
                        .clipped()

                    VStack(spacing: 16) {
                        Text("\(profile.firstName) \(profile.lastName), \(profile.age)")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        detailRow(icon: "envelope.fill", text: profile.email)
                        detailRow(icon: "phone.fill", text: profile.phone)
                        detailRow(icon: "mappin.and.ellipse", text: "\(profile.city), \(profile.country)")
                        detailRow(icon: "calendar", text: "Registered: \(profile.registeredDate.formatted(date: .abbreviated, time: .omitted))")
                    }
                    .padding(.horizontal)

                    HStack(spacing: 30) {
                        Button("Decline") { Task { await viewModel.decline() } }
                            .buttonStyle(ActionButtonStyle(color: .red, isSelected: profile.status == .declined))

                        Button("Accept") { Task { await viewModel.accept() } }
                            .buttonStyle(ActionButtonStyle(color: .green, isSelected: profile.status == .accepted))
                    }
                    .padding(.top, 20)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProfile()
        }
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

// Custom button style for detail view actions
struct ActionButtonStyle: ButtonStyle {
    let color: Color
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(isSelected ? .white : color)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? color : color.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: isSelected ? 0 : 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut, value: configuration.isPressed)
    }
}
