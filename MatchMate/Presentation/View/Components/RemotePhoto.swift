//
//  RemotePhoto.swift
//  MatchMate
//

import SwiftUI
import Kingfisher

/// Random User photos are low resolution, so a plain full-bleed stretch looks blocky. This
/// renders the image blurred as an ambient fill with a crisp, smaller copy composited on top.
/// A `Rectangle` anchors the layout to exactly the proposed size; the fill images overflow and
/// are clipped, so this never pushes its container wider than intended.
struct RemotePhoto: View {
    let url: URL?
    /// Side length of the crisp foreground image.
    var foreground: CGFloat = 200
    var cornerRadius: CGFloat = 28

    var body: some View {
        Rectangle()
            .fill(Color(.secondarySystemBackground))
            .overlay {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 18)
                    .overlay(Color.black.opacity(0.1))
                    .overlay(Palette.plum.opacity(0.08))
            }
            .overlay {
                KFImage(url)
                    .resizable()
                    .placeholder {
                        Image(systemName: "person.fill")
                            .font(.system(size: foreground * 0.4))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .scaledToFill()
                    .frame(width: foreground, height: foreground)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(.white.opacity(0.6), lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
            }
            .clipped()
    }
}
