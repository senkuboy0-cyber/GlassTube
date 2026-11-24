//
//  VideoCard.swift
//  GlassTube
//
//  Glass video card: springy press, shimmering thumbnail placeholder,
//  duration badge, channel avatar and a context menu.
//  Also contains the skeleton shimmer card.
//

import SwiftUI

struct VideoCard: View {
    @EnvironmentObject private var app: AppEnvironment
    let item: VideoItem

    var body: some View {
        Button {
            app.play(item)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                thumbnail

                HStack(spacing: 12) {
                    channelAvatar

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(Theme.body(15.5))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(Theme.ink)
                        Text(metaLine)
                            .font(Theme.body(12.5))
                            .foregroundStyle(Theme.inkDim)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    Menu {
                        Button {
                            app.toggleWatchLater(item)
                        } label: {
                            Label(
                                app.isWatchLater(item) ? "Remove from Watch Later" : "Watch Later",
                                systemImage: "bookmark"
                            )
                        }
                        if let url = item.watchURL {
                            ShareLink(item: url) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.inkDim)
                            .rotationEffect(.degrees(90))
                            .frame(width: 30, height: 30)
                    }
                }
            }
            .padding(10)
            .glassPanel(.thin, cornerRadius: 24, shadow: true)
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: - Pieces

    private var thumbnail: some View {
        ZStack(alignment: .bottomTrailing) {
            AsyncImage(url: item.thumbnail) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Image(systemName: "play.rectangle.on.rectangle")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.inkDim)
                default:
                    Rectangle()
                        .fill(Theme.bgSoft)
                        .shimmer()
                }
            }
            .frame(height: 205)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(item.displayDuration)
                .font(Theme.mono)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(8)
        }
    }

    private var channelAvatar: some View {
        ZStack {
            Circle().fill(Theme.coolGradient)
            Text(String(item.channel.prefix(1)).uppercased())
                .font(Theme.title(14, weight: .heavy))
                .foregroundStyle(.white)
        }
        .frame(width: 38, height: 38)
    }

    private var metaLine: String {
        var parts: [String] = []
        if !item.channel.isEmpty { parts.append(item.channel) }
        if !item.viewsText.isEmpty { parts.append(item.viewsText) }
        if !item.publishedText.isEmpty { parts.append(item.publishedText) }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Skeleton

/// Shimmering placeholder shown while a feed loads.
struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.bgSoft)
                .frame(height: 205)
                .shimmer()

            HStack(spacing: 12) {
                Circle()
                    .fill(Theme.bgSoft)
                    .frame(width: 38, height: 38)
                    .shimmer()
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.bgSoft)
                        .frame(width: 220, height: 12)
                        .shimmer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.bgSoft)
                        .frame(width: 140, height: 10)
                        .shimmer()
                }
            }
        }
        .padding(10)
        .glassPanel(.thin, cornerRadius: 24, shadow: false)
    }
}
