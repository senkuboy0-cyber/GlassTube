//
//  GlassTubeApp.swift
//  GlassTube
//
//  App entry point. Dark scheme + accent tint so the glass surfaces glow.
//

import SwiftUI

@main
struct GlassTubeApp: App {
    @StateObject private var app = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootContainer()
                .environmentObject(app)
                .tint(Theme.accent)
                .preferredColorScheme(.dark)
        }
    }
}
