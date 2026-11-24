//
//  Theme.swift
//  GlassTube
//
//  Design tokens for GlassTube's liquid-glass visual language:
//  palette, gradients and rounded typography.
//

import SwiftUI

extension Color {
    /// Builds a color from a 24-bit hex value, e.g. `0xFF3B5C`.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

/// Central design tokens.
enum Theme {
    // MARK: Palette

    static let bgDeep     = Color(hex: 0x0A0912)
    static let bgSoft     = Color(hex: 0x1A1726)
    static let ink        = Color(hex: 0xF5F3FF)
    static let inkDim     = Color(hex: 0xB9B4C7)
    static let accent     = Color(hex: 0xFF3B5C)
    static let accentHot  = Color(hex: 0xFF7A3D)
    static let accentCool = Color(hex: 0x8E6BFF)

    // MARK: Gradients

    static let heroGradient = LinearGradient(
        colors: [accent, accentHot],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let coolGradient = LinearGradient(
        colors: [accentCool, Color(hex: 0x4DA6FF)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Typography (rounded design matches the glass language)

    static func title(_ size: CGFloat = 22, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static let mono = Font.system(size: 12, weight: .semibold, design: .monospaced)
}
