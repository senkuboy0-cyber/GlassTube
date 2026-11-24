//
//  Glass.swift
//  GlassTube
//
//  Liquid-glass material system: layered materials, specular sheen and an
//  inner light border, applied with the `.glassPanel(...)` modifier.
//

import SwiftUI

/// Depth of the glass effect.
enum GlassDepth {
    case thin, regular, thick

    var material: Material {
        switch self {
        case .thin:     return .ultraThinMaterial
        case .regular:  return .regularMaterial
        case .thick:    return .thickMaterial
        }
    }
}

private struct GlassPanelModifier: ViewModifier {
    let depth: GlassDepth
    let cornerRadius: CGFloat
    let tint: Color
    let shadow: Bool

    func body(content: Content) -> some View {
        content
            // Tint bleed under the material keeps panels warm at the edges.
            .background(tint.opacity(0.08))
            .background(depth.material, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            // Inner light border: bright on the top-left like light passing through glass.
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.34), .white.opacity(0.05), .white.opacity(0.16)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
            )
            // Specular sheen sweeping the top of the panel.
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.13), .white.opacity(0.02), .clear],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.6)
                        )
                    )
                    .allowsHitTesting(false)
            )
            .shadow(color: .black.opacity(shadow ? 0.32 : 0), radius: shadow ? 16 : 0, y: shadow ? 8 : 0)
    }
}

extension View {
    /// Wraps content in a frosted liquid-glass panel.
    func glassPanel(
        _ depth: GlassDepth = .regular,
        cornerRadius: CGFloat = 22,
        tint: Color = Theme.accent,
        shadow: Bool = true
    ) -> some View {
        modifier(GlassPanelModifier(depth: depth, cornerRadius: cornerRadius, tint: tint, shadow: shadow))
    }
}

/// Pill glass button with a spring press.
struct GlassButtonStyle: ButtonStyle {
    var tint: Color = Theme.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(16))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .glassPanel(.thin, cornerRadius: 16, tint: tint, shadow: false)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(Spring.snappy, value: configuration.isPressed)
    }
}

/// Big circular glass play/pause button.
struct GlassPlayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.ultraThinMaterial, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(Spring.snappy, value: configuration.isPressed)
    }
}
