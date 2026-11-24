//
//  AppEnvironment.swift
//  GlassTube
//
//  App-wide state: splash phase, tab selection, search session, player
//  session and persisted lists (watch later, region).
//

import SwiftUI

@MainActor
final class AppEnvironment: ObservableObject {

    enum Phase { case splash, main }

    enum Tab: String, CaseIterable, Identifiable {
        case home, search, trending, library
        var id: String { rawValue }
    }

    // MARK: Published state

    @Published var phase: Phase = .splash
    @Published var selectedTab: Tab = .home

    // Search session
    @Published private(set) var searchResults: [VideoItem] = []
    @Published private(set) var searchError: String?
    @Published var suggestions: [String] = []

    // Personal lists
    @Published var watchLater: [VideoItem] = [] { didSet { persistWatchLater() } }
    @Published private(set) var history: [VideoItem] = []

    // Player session
    @Published var nowPlaying: VideoItem?
    @Published private(set) var stream: PlayerStream?
    @Published private(set) var streamError: String?
    @Published var isPlayerPresented = false

    // Settings
    @Published var region: String {
        didSet {
            tube.locale.gl = region
            UserDefaults.standard.set(region, forKey: "gt.region")
        }
    }

    let tube = InnerTube()

    private let watchLaterKey = "gt.watchLater"

    init() {
        region = UserDefaults.standard.string(forKey: "gt.region") ?? "US"
        tube.locale.gl = region
        loadWatchLater()
    }

    // MARK: - Feeds (used by FeedView)

    /// Generic browse fetch — mirrors `InnerTube.browse`.
    func browse(_ browseId: String) async throws -> [VideoItem] {
        try await tube.browse(browseId)
    }

    // MARK: - Search

    func search(_ query: String, params: String?) async {
        searchError = nil
        do {
            let items = try await tube.search(query, params: params)
            withAnimation(Spring.gentle) { searchResults = items }
        } catch {
            withAnimation(Spring.gentle) { searchResults = [] }
            searchError = error.localizedDescription
        }
    }

    func suggestions(for query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            suggestions = []
            return
        }
        do {
            suggestions = try await tube.suggestions(trimmed)
        } catch {
            // Suggestions are best-effort; keep the old list on failure.
        }
    }

    // MARK: - Player session

    func play(_ item: VideoItem) {
        withAnimation(Spring.opulent) {
            nowPlaying = item
            stream = nil
            streamError = nil
            isPlayerPresented = true
        }
        Haptics.thump()
        appendHistory(item)
        Task { await resolveStream(for: item) }
    }

    func resolveStream(for item: VideoItem) async {
        do {
            let resolved = try await tube.player(item.id)
            withAnimation(Spring.gentle) { stream = resolved }
        } catch {
            streamError = error.localizedDescription
        }
    }

    func retryStream() async {
        guard let item = nowPlaying else { return }
        stream = nil
        streamError = nil
        await resolveStream(for: item)
    }

    func dismissPlayer() {
        withAnimation(Spring.opulent) { isPlayerPresented = false }
    }

    func stopPlayback() {
        withAnimation(Spring.opulent) {
            isPlayerPresented = false
            nowPlaying = nil
            stream = nil
            streamError = nil
        }
        Haptics.tap()
    }

    // MARK: - Watch later / history

    func toggleWatchLater(_ item: VideoItem) {
        if let index = watchLater.firstIndex(where: { $0.id == item.id }) {
            watchLater.remove(at: index)
            Haptics.tap()
        } else {
            withAnimation(Spring.bouncy) { watchLater.insert(item, at: 0) }
            Haptics.yay()
        }
    }

    func isWatchLater(_ item: VideoItem) -> Bool {
        watchLater.contains { $0.id == item.id }
    }

    private func appendHistory(_ item: VideoItem) {
        history.removeAll { $0.id == item.id }
        history.insert(item, at: 0)
        if history.count > 40 {
            history.removeLast(history.count - 40)
        }
    }

    // MARK: - Persistence

    private func persistWatchLater() {
        if let data = try? JSONEncoder().encode(watchLater) {
            UserDefaults.standard.set(data, forKey: watchLaterKey)
        }
    }

    private func loadWatchLater() {
        guard let data = UserDefaults.standard.data(forKey: watchLaterKey),
              let items = try? JSONDecoder().decode([VideoItem].self, from: data) else { return }
        watchLater = items
    }
}
