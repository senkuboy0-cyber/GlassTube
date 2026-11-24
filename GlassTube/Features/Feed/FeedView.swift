//
//  FeedView.swift
//  GlassTube
//
//  Scrollable video feed (Home & Trending): stretchy parallax header,
//  feed chips, skeleton shimmer, pull-to-refresh and spring-staggered cards.
//

import SwiftUI

struct FeedView: View {
    enum Kind {
        case home      // FEwhat_to_watch
        case trending  // FEtrending
    }

    private struct FeedChip: Identifiable {
        let id: Int
        let title: String
        let browseId: String
    }

    @EnvironmentObject private var app: AppEnvironment
    let kind: Kind

    @State private var items: [VideoItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedFeed = 0
    @Namespace private var chipNamespace

    private var chips: [FeedChip] {
        kind == .home
            ? [
                FeedChip(id: 0, title: "For You", browseId: "FEwhat_to_watch"),
                FeedChip(id: 1, title: "Trending", browseId: "FEtrending"),
                FeedChip(id: 2, title: "Music", browseId: "FEmusic"),
                FeedChip(id: 3, title: "Gaming", browseId: "FEgaming"),
            ]
            : [
                FeedChip(id: 0, title: "Now", browseId: "FEtrending"),
                FeedChip(id: 1, title: "Music", browseId: "FEmusic"),
                FeedChip(id: 2, title: "Gaming", browseId: "FEgaming"),
            ]
    }

    private var currentChip: FeedChip {
        chips[min(selectedFeed, chips.count - 1)]
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 18) {
                header
                feedChips

                if isLoading && items.isEmpty {
                    ForEach(0..<5, id: \.self) { index in
                        SkeletonCard()
                            .staggeredIn(index)
                            .padding(.horizontal, 16)
                    }
                } else if let error = errorMessage, items.isEmpty {
                    ErrorPanel(message: error) {
                        Task { await load(currentChip, force: true) }
                    }
                } else if items.isEmpty {
                    ContentUnavailableView(
                        "Nothing here yet",
                        systemImage: "tv.slash",
                        description: Text("Pull down to refresh the feed.")
                    )
                    .foregroundStyle(Theme.inkDim)
                    .padding(.top, 60)
                } else {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        VideoCard(item: item)
                            .staggeredIn(index)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, 120)
        }
        .refreshable { await load(currentChip, force: true) }
        .task { await load(currentChip) }
    }

    // MARK: - Header

    private var header: some View {
        StretchyHeader(height: 110) {
            HStack(spacing: 12) {
                GlassTubeLogo(size: 42)
                VStack(alignment: .leading, spacing: 1) {
                    Text(kind == .home ? "Home" : "Trending")
                        .font(Theme.title(30, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(kind == .home ? "Fresh from your feed" : "What the world watches")
                        .font(Theme.body(13))
                        .foregroundStyle(Theme.inkDim)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Chips

    private var feedChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(chips) { chip in
                    let selected = chip.id == selectedFeed
                    Button {
                        guard chip.id != selectedFeed else { return }
                        withAnimation(Spring.snappy) {
                            selectedFeed = chip.id
                            items = []
                            errorMessage = nil
                        }
                        Haptics.select()
                        Task { await load(chip, force: true) }
                    } label: {
                        Text(chip.title)
                            .font(Theme.body(13.5))
                            .foregroundStyle(selected ? .white : Theme.inkDim)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background {
                                if selected {
                                    Capsule()
                                        .fill(Theme.heroGradient)
                                        .matchedGeometryEffect(id: "feed-chip", in: chipNamespace)
                                        .shadow(color: Theme.accent.opacity(0.45), radius: 8, y: 2)
                                } else {
                                    Capsule().fill(.white.opacity(0.08))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Loading

    private func load(_ chip: FeedChip, force: Bool = false) async {
        if !force && !items.isEmpty { return }
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await app.browse(chip.browseId)
            withAnimation(Spring.gentle) { items = fetched }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
