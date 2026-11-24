//
//  Motion.swift
//  GlassTube
//
//  Reusable motion primitives: springy pressable cards, shimmer light bands,
//  staggered list entrances and a rubber-band stretchy header.
//

import SwiftUI

// MARK: - Pressable surfaces

/// Springy press-down used by every tappable card.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(Spring.snappy, value: configuration.isPressed)
    }
}

// MARK: - Shimmer

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.20), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: phase * geo.size.width * 1.6)
                    .blendMode(.plusLighter)
                }
                .allowsHitTesting(false)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Moving light band — used on skeletons and glass surfaces.
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Staggered entrance

private struct StaggerInModifier: ViewModifier {
    let index: Int
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 26)
            .scaleEffect(shown ? 1 : 0.97)
            .onAppear {
                withAnimation(Spring.bouncy.delay(Double(index % 9) * 0.05)) {
                    shown = true
                }
            }
    }
}

extension View {
    /// Springs the view in with a per-index stagger (list entrances).
    func staggeredIn(_ index: Int) -> some View {
        modifier(StaggerInModifier(index: index))
    }
}

// MARK: - Stretchy header

/// Rubber-band stretchy header for ScrollViews.
struct StretchyHeader<Content: View>: View {
    var height: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let stretched = minY > 0
            content()
                .frame(
                    width: geo.size.width,
                    height: stretched ? height + minY : height,
                    alignment: .bottom
                )
                .offset(y: stretched ? -minY : 0)
                .clipped()
        }
        .frame(height: height)
    }
}
