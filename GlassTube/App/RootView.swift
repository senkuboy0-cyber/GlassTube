//
//  RootView.swift
//  GlassTube
//
//  Root container: splash -> main hand-off, tab content with spring
//  transitions, floating glass tab bar, mini player and the full-screen
//  player overlay.
//

import SwiftUI

struct RootContainer: View {
    @EnvironmentObject private var app: AppEnvironment

    var body: some View {
        ZStack {
            FluidBackground()

            switch app.phase {
            case .splash:
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))

            case .main:
                mainContent
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.97)),
                            removal: .opacity
                        )
                    )
            }

            if app.isPlayerPresented {
                PlayerHostView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(Spring.opulent, value: app.phase)
        .animation(Spring.opulent, value: app.isPlayerPresented)
    }

    @ViewBuilder
    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch app.selectedTab {
                case .home:     FeedView(kind: .home)
                case .search:   SearchView()
                case .trending: FeedView(kind: .trending)
                case .library:  LibraryView()
                }
            }
            .id(app.selectedTab)
            .transition(.scale(scale: 0.985).combined(with: .opacity))
            .animation(Spring.snappy, value: app.selectedTab)

            if let item = app.nowPlaying, !app.isPlayerPresented {
                MiniPlayerBar(item: item)
                    .zIndex(5)
                    .padding(.bottom, 76) // clears the floating tab bar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingTabBar()
        }
    }
}
