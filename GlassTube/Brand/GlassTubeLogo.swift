//
//  GlassTubeLogo.swift
//  GlassTube
//
//  The GlassTube logo, drawn entirely in code — a glass squircle with a
//  gradient core and a rounded play glyph, plus a pulsing variant for the
//  splash screen. No image assets required.
//

import SwiftUI

/// Rounded play glyph used in the logo and badges.
struct PlayGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Optical center: nudge the triangle slightly right of geometric center.
        let top = CGPoint(x: w * 0.36, y: h * 0.24)
        let right = CGPoint(x: w * 0.82, y: h * 0.50)
        let bottom = CGPoint(x: w * 0.36, y: h * 0.76)
        path.move(to: top)
        path.addLine(to: right)
        path.addLine(to: bottom)
        path.closeSubpath()
        return path
    }
}

/// The static GlassTube mark.
struct GlassTubeLogo: View {
    var size: CGFloat = 96
    var glow: Bool = false

    var body: some View {
        ZStack {
            // Gradient core
            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.accent, Theme.accentHot, Color(hex: 0xFF4E86)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            // Glass core: vertical light falloff
            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.30), .white.opacity(0.02), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            // Light edge
            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.55), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(1, size * 0.02)
                )
            // Play glyph
            PlayGlyph()
                .fill(
                    LinearGradient(
                        colors: [.white, Color(hex: 0xFFE7EC)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.46, height: size * 0.46)
                .offset(x: size * 0.02)
                .shadow(color: .black.opacity(0.25), radius: size * 0.05, y: size * 0.02)
        }
        .frame(width: size, height: size)
        .shadow(
            color: Theme.accent.opacity(glow ? 0.55 : 0.30),
            radius: size * (glow ? 0.30 : 0.18),
            y: size * 0.06
        )
    }
}

/// Splash variant: breathing glow behind the mark.
struct PulsingLogo: View {
    var size: CGFloat = 120
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.accent.opacity(0.45), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size
                    )
                )
                .frame(width: size * 2.2, height: size * 2.2)
                .scaleEffect(pulse ? 1.15 : 0.90)
                .opacity(pulse ? 0.75 : 0.40)

            GlassTubeLogo(size: size, glow: true)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
