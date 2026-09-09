//
//  SwipeDeck.swift
//  MatchMate
//

import SwiftUI

enum SwipeDecision: Equatable {
    case like, pass

    var status: MatchStatus { self == .like ? .accepted : .declined }
}

/// A Tinder-style card stack. Renders up to `depth` cards, the front one draggable. A drag past
/// the threshold — or a `command` pushed from the action bar — flies the card off and reports
/// the decision.
///
/// The deck is a pure function of `profiles`: when a decision changes a profile's status the
/// parent removes it from `profiles`, the card leaves the tree, and the next one slides forward.
struct SwipeDeck: View {
    let profiles: [Profile]
    /// Set by the parent's action buttons; the deck consumes it and resets it to `nil`.
    @Binding var command: SwipeDecision?
    var onDecision: (Profile, SwipeDecision) -> Void
    var onTap: (Profile) -> Void

    private let depth = 3
    private let swipeThreshold: CGFloat = 100
    /// Card width : height. Portrait, close to a playing card.
    private let ratio: CGFloat = 0.66

    @State private var drag: CGSize = .zero
    /// Cards mid-flight, keyed by id, with the translation they're exiting toward.
    @State private var exiting: [String: CGSize] = [:]

    private var visible: [Profile] { Array(profiles.prefix(depth)) }

    var body: some View {
        GeometryReader { geo in
            // Fill the box the parent gives us: as tall as possible, width follows the ratio,
            // never wider than the box. Whatever slack remains is split evenly top/bottom.
            let width = min(geo.size.width, geo.size.height * ratio)
            let height = width / ratio

            ZStack {
                ForEach(Array(visible.enumerated()), id: \.element.id) { pair in
                    card(pair.element, index: pair.offset, size: CGSize(width: width, height: height))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(.spring(response: 0.42, dampingFraction: 0.78), value: profiles.map(\.id))
        }
        .onChange(of: profiles.map(\.id)) { _, ids in
            for key in Array(exiting.keys) where !ids.contains(key) {
                exiting.removeValue(forKey: key)
            }
        }
        .onChange(of: command) { _, newValue in
            guard let decision = newValue, let front = visible.first else { return }
            throwCard(front, decision, from: CGSize(width: 0, height: -40))
            command = nil
        }
    }

    // MARK: - Card

    @ViewBuilder
    private func card(_ profile: Profile, index: Int, size: CGSize) -> some View {
        let isFront = index == 0
        let exit = exiting[profile.id]
        let translation = exit ?? (isFront ? drag : .zero)
        let progress = isFront && exit == nil ? drag.width / swipeThreshold : 0
        let settled = isFront || exit != nil

        ProfileDeckCard(profile: profile, size: size, dragProgress: progress)
            .scaleEffect(settled ? 1 : 1 - CGFloat(index) * 0.04)
            .offset(y: settled ? 0 : CGFloat(index) * 12)
            .offset(translation)
            .rotationEffect(.degrees(Double(translation.width) / 16), anchor: .bottom)
            .opacity(exit == nil ? 1 : 0)
            .zIndex(isFront ? 100 : Double(depth - index))
            .allowsHitTesting(isFront && exit == nil)
            .onTapGesture { onTap(profile) }
            .gesture(isFront ? dragGesture(for: profile) : nil)
    }

    private func dragGesture(for profile: Profile) -> some Gesture {
        DragGesture()
            .onChanged { drag = $0.translation }
            .onEnded { value in
                if value.translation.width > swipeThreshold {
                    throwCard(profile, .like, from: value.translation)
                } else if value.translation.width < -swipeThreshold {
                    throwCard(profile, .pass, from: value.translation)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { drag = .zero }
                }
            }
    }

    private func throwCard(_ profile: Profile, _ decision: SwipeDecision, from translation: CGSize) {
        guard exiting[profile.id] == nil else { return }
        let offX: CGFloat = decision == .like ? 560 : -560
        Haptics.impact(.medium)
        withAnimation(.easeIn(duration: 0.28)) {
            exiting[profile.id] = CGSize(width: offX, height: translation.height)
            drag = .zero
        }
        Task {
            try? await Task.sleep(for: .milliseconds(170))
            onDecision(profile, decision)
        }
    }
}
