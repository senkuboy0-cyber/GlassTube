//
//  TabBar.swift
//  GlassTube
//
//  Floating liquid-glass tab bar: matched-geometry selection pill,
//  bouncing SF Symbols and haptics on every switch.
//

import SwiftUI

struct FloatingTabBar: View {
    @EnvironmentObject private var app: AppEnvironment
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppEnvironment.Tab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(6)
        .glassPanel(.regular, cornerRadius: 26, shadow: true)
        .padding(.horizontal, 40)
        .padding(.vertical, 6)
    }

    private func tabButton(_ tab: AppEnvironment.Tab) -> some View {
        let selected = app.selectedTab == tab
        return Button {
            guard !selected else { return }
            withAnimation(Spring.snappy) { app.selectedTab = tab }
            Haptics.select()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 19, weight: .semibold))
                    .symbolEffect(.bounce, options: .nonRepeating, value: selected)
                Text(tab.label)
                    .font(Theme.body(10))
            }
            .foregroundStyle(selected ? Color.white : Theme.inkDim)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background {
                if selected {
                    Capsule()
                        .fill(Theme.heroGradient)
                        .matchedGeometryEffect(id: "tab-pill", in: pill)
                        .shadow(color: Theme.accent.opacity(0.5), radius: 10, y: 3)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

extension AppEnvironment.Tab {
    var icon: String {
        switch self {
        case .home:     return "house.fill"
        case .search:   return "magnifyingglass"
        case .trending: return "flame.fill"
        case .library:  return "square.stack.fill"
        }
    }

    var label: String {
        switch self {
        case .home:     return "Home"
        case .search:   return "Search"
        case .trending: return "Trending"
        case .library:  return "Library"
        }
    }
}
