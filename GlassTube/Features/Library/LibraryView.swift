//
//  LibraryView.swift
//  GlassTube
//
//  Watch later, recently played, region settings and engine info.
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var app: AppEnvironment

    private let regions = ["US", "GB", "CA", "DE", "FR", "IN", "JP", "BR", "KR", "BD"]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                header
                watchLater
                history
                settings
                about
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 110)
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 12) {
            GlassTubeLogo(size: 42)
            Text("Library")
                .font(Theme.title(30, weight: .heavy))
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
        }
    }

    private var watchLater: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Watch Later", systemImage: "bookmark.fill")
            if app.watchLater.isEmpty {
                EmptyHint(text: "Bookmark videos from any card's menu.")
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(app.watchLater.enumerated()), id: \.element.id) { index, item in
                        LibraryRow(item: item, isSaved: true) {
                            app.toggleWatchLater(item)
                        }
                        .staggeredIn(index)
                    }
                }
            }
        }
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Recently Played", systemImage: "clock.arrow.circlepath")
            if app.history.isEmpty {
                EmptyHint(text: "Videos you play will appear here.")
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(app.history.prefix(8).enumerated()), id: \.element.id) { index, item in
                        LibraryRow(item: item, isSaved: app.isWatchLater(item)) {
                            app.toggleWatchLater(item)
                        }
                        .staggeredIn(index)
                    }
                }
            }
        }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Settings", systemImage: "gearshape.fill")
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Region", systemImage: "globe")
                        .font(Theme.body(14))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Menu {
                        ForEach(regions, id: \.self) { candidate in
                            Button(candidate) {
                                withAnimation(Spring.snappy) { app.region = candidate }
                                Haptics.select()
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(app.region)
                                .font(Theme.mono)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.heroGradient, in: Capsule())
                    }
                }

                Divider()
                    .overlay(.white.opacity(0.12))

                HStack {
                    Label("InnerTube engine", systemImage: "cpu")
                        .font(Theme.body(14))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("innertubex v0.13.1 (Swift)")
                        .font(Theme.mono)
                        .foregroundStyle(Theme.inkDim)
                }
            }
            .padding(16)
            .glassPanel(.thin, cornerRadius: 20, shadow: false)
        }
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "About", systemImage: "info.circle.fill")
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    GlassTubeLogo(size: 44, glow: true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("GlassTube")
                            .font(Theme.title(17, weight: .heavy))
                            .foregroundStyle(.white)
                        Text("Version 1.0.0 · Build 1")
                            .font(Theme.mono)
                            .foregroundStyle(Theme.inkDim)
                    }
                }

                Text("An independent, open-source YouTube client built with SwiftUI, liquid-glass design and real spring physics. Powered by the InnerTubeX API surface (GPL-3.0). Not affiliated with, endorsed by, or sponsored by YouTube or Google.")
                    .font(Theme.body(12.5))
                    .foregroundStyle(Theme.inkDim)

                Link(destination: URL(string: "https://github.com/MetrolistGroup/innertubex")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                        Text("MetrolistGroup/innertubex")
                    }
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.accent)
                }
            }
            .padding(16)
            .glassPanel(.thin, cornerRadius: 20, shadow: false)
        }
    }
}

// MARK: - Helpers

private struct EmptyHint: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkle")
            Text(text)
        }
        .font(Theme.body(13))
        .foregroundStyle(Theme.inkDim.opacity(0.7))
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(.thin, cornerRadius: 18, shadow: false)
    }
}

private struct LibraryRow: View {
    @EnvironmentObject private var app: AppEnvironment
    let item: VideoItem
    let isSaved: Bool
    let onToggleSave: () -> Void

    var body: some View {
        Button {
            app.play(item)
        } label: {
            HStack(spacing: 12) {
                AsyncImage(url: item.thumbnail) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Rectangle().fill(Theme.bgSoft)
                    }
                }
                .frame(width: 110, height: 62)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(Theme.body(13.5))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(item.channel)
                        .font(Theme.body(11.5))
                        .foregroundStyle(Theme.inkDim)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Button(action: onToggleSave) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isSaved ? Theme.accent : Theme.inkDim)
                }
            }
            .padding(10)
            .glassPanel(.thin, cornerRadius: 18, shadow: false)
        }
        .buttonStyle(PressableStyle(scale: 0.98))
    }
}
