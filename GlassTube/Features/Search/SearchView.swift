//
//  SearchView.swift
//  GlassTube
//
//  Glass search field with debounced live suggestions, filter chips
//  (InnerTube search params) and spring-staggered results.
//

import SwiftUI

struct SearchView: View {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case videos = "Videos"
        case live = "Live"

        var id: String { rawValue }

        /// InnerTube search `params` (web-style encoded filters).
        var params: String? {
            switch self {
            case .all:    return nil
            case .videos: return "EgIQAQ%3D%3D"
            case .live:   return "EgJAAQ%3D%3D"
            }
        }
    }

    @EnvironmentObject private var app: AppEnvironment

    @State private var query = ""
    @State private var results: [VideoItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searched = false
    @State private var filter: Filter = .all
    @State private var suggestionsTask: Task<Void, Never>?
    @FocusState private var fieldFocused: Bool
    @Namespace private var chipNamespace

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                GlassTubeLogo(size: 36)
                Text("Search")
                    .font(Theme.title(30, weight: .heavy))
                    .foregroundStyle(.white)
                Spacer()
            }

            searchField

            HStack(spacing: 8) {
                ForEach(Filter.allCases) { candidate in
                    let selected = filter == candidate
                    Button {
                        withAnimation(Spring.snappy) { filter = candidate }
                        Haptics.select()
                        if searched { runSearch() }
                    } label: {
                        Text(candidate.rawValue)
                            .font(Theme.body(13))
                            .foregroundStyle(selected ? .white : Theme.inkDim)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background {
                                if selected {
                                    Capsule()
                                        .fill(Theme.heroGradient)
                                        .matchedGeometryEffect(id: "search-chip", in: chipNamespace)
                                } else {
                                    Capsule().fill(.white.opacity(0.08))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.inkDim)

            TextField("Search YouTube", text: $query)
                .font(Theme.body(16))
                .foregroundStyle(.white)
                .focused($fieldFocused)
                .submitLabel(.search)
                .onSubmit { runSearch() }
                .onChange(of: query) { _, newValue in
                    debounceSuggestions(newValue)
                }

            if !query.isEmpty {
                Button {
                    withAnimation(Spring.snappy) {
                        query = ""
                        results = []
                        searched = false
                        app.suggestions = []
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.inkDim)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassPanel(.regular, cornerRadius: 18, shadow: false)
        .animation(Spring.snappy, value: query.isEmpty)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if !searched && !app.suggestions.isEmpty {
                    suggestionPanel
                } else if isLoading {
                    ForEach(0..<4, id: \.self) { index in
                        SkeletonCard()
                            .staggeredIn(index)
                            .padding(.horizontal, 16)
                    }
                } else if let error = errorMessage {
                    ErrorPanel(message: error) {
                        runSearch()
                    }
                } else if searched && results.isEmpty {
                    ContentUnavailableView(
                        "No results",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different query or filter.")
                    )
                    .foregroundStyle(Theme.inkDim)
                    .padding(.top, 60)
                } else {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, item in
                        VideoCard(item: item)
                            .staggeredIn(index)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 14)
            .padding(.bottom, 110)
        }
        .animation(Spring.gentle, value: app.suggestions)
    }

    private var suggestionPanel: some View {
        VStack(spacing: 0) {
            ForEach(app.suggestions, id: \.self) { suggestion in
                Button {
                    query = suggestion
                    fieldFocused = false
                    runSearch()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.inkDim)
                        Text(suggestion)
                            .font(Theme.body(14.5))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "arrow.up.left")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkDim.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .glassPanel(.thin, cornerRadius: 20, shadow: true)
        .padding(.horizontal, 16)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Actions

    private func debounceSuggestions(_ text: String) {
        suggestionsTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            app.suggestions = []
            return
        }
        suggestionsTask = Task {
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }
            await app.suggestions(for: trimmed)
        }
    }

    private func runSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        fieldFocused = false
        suggestionsTask?.cancel()
        app.suggestions = []
        isLoading = true
        errorMessage = nil
        searched = true
        Haptics.tick()

        let params = filter.params
        Task {
            await app.search(trimmed, params: params)
            isLoading = false
            results = app.searchResults
            errorMessage = app.searchError
        }
    }
}
