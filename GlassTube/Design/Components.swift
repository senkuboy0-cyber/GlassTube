//
//  Components.swift
//  GlassTube
//
//  Small shared building blocks: error panel, chips and section headers.
//

import SwiftUI

/// Glass error panel with optional retry action.
struct ErrorPanel: View {
    let message: String
    var retry: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Theme.accent)
            Text(message)
                .font(Theme.body(13))
                .foregroundStyle(Theme.inkDim)
                .multilineTextAlignment(.center)
            if let retry {
                Button(action: retry) {
                    Text("Try again")
                }
                .buttonStyle(GlassButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .glassPanel(.regular, cornerRadius: 24)
        .padding(.horizontal, 16)
    }
}

/// Small labelled chip.
struct GlassChip: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(Theme.body(11.5))
        }
        .foregroundStyle(Theme.inkDim)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.08), in: Capsule())
    }
}

/// Section header row.
struct SectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.accent)
            Text(title)
                .font(Theme.title(17, weight: .bold))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.leading, 4)
    }
}
