//
//  SplashView.swift
//  GlassTube
//
//  Splash screen: code-drawn logo springs in, physics-driven loading dots,
//  per-letter wordmark stagger, drag parallax with momentum reset, then a
//  cinematic hand-off to the main UI.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var app: AppEnvironment

    @State private var logoShown = false
    @State private var lettersShown = false
    @State private var dotsShown = false
    @State private var parallax: CGSize = .zero

    private let wordmark = "GLASSTUBE"

    var body: some View {
        ZStack {
            FluidBackground(intensity: 1.2)

            VStack(spacing: 28) {
                PulsingLogo(size: 116)
                    .scaleEffect(logoShown ? 1 : 0.35)
                    .opacity(logoShown ? 1 : 0)
                    .offset(x: parallax.width, y: parallax.height)
                    .animation(Spring.bouncy, value: logoShown)

                // Wordmark — per-letter spring stagger.
                HStack(spacing: 2) {
                    ForEach(Array(wordmark.enumerated()), id: \.offset) { index, letter in
                        Text(String(letter))
                            .font(Theme.title(30, weight: .heavy))
                            .foregroundStyle(.white)
                            .opacity(lettersShown ? 1 : 0)
                            .offset(y: lettersShown ? 0 : 18)
                            .scaleEffect(lettersShown ? 1 : 0.6)
                            .animation(Spring.bouncy.delay(Double(index) * 0.045), value: lettersShown)
                    }
                }
                .offset(x: parallax.width * 0.6, y: parallax.height * 0.6)

                Text("Liquid glass · Real spring physics · InnerTubeX")
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.inkDim.opacity(0.85))
                    .opacity(lettersShown ? 1 : 0)
                    .animation(Spring.gentle.delay(0.55), value: lettersShown)

                PhysicsLoadingDots(visible: dotsShown)
                    .opacity(dotsShown ? 1 : 0)
                    .animation(Spring.gentle, value: dotsShown)
            }

            VStack {
                Spacer()
                Text("Powered by innertubex · v0.13.1 API surface")
                    .font(Theme.mono)
                    .foregroundStyle(Theme.inkDim.opacity(0.55))
                    .padding(.bottom, 24)
            }
        }
        .contentShape(Rectangle())
        .gesture(parallaxGesture)
        .onAppear(perform: entrance)
        .task { await handOff() }
    }

    // Drag parallax: follows the finger directly, springs home on release.
    private var parallaxGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                parallax = CGSize(
                    width: value.translation.width * 0.25,
                    height: value.translation.height * 0.25
                )
            }
            .onEnded { _ in
                // Release velocity decays naturally; the spring settles home.
                withAnimation(Spring.gentle) { parallax = .zero }
            }
    }

    private func entrance() {
        withAnimation(Spring.bouncy) { logoShown = true }
        withAnimation(Spring.bouncy.delay(0.28)) { lettersShown = true }
        withAnimation(Spring.gentle.delay(0.5)) { dotsShown = true }
    }

    private func handOff() async {
        try? await Task.sleep(for: .seconds(2.6))
        guard app.phase == .splash else { return }
        withAnimation(Spring.opulent) { app.phase = .main }
    }
}

/// Loading dots driven by the analytic spring solver — every dot is a real
/// damped oscillator kicked with an initial velocity, sampled at 60 Hz.
struct PhysicsLoadingDots: View {
    var visible: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { index in
                    let phase = fmod(t + Double(index) * 0.22, 1.2)
                    let offset = phase < 0.5
                        ? SpringPhysics.position(x0: 0, v0: 120, stiffness: 140, damping: 10, t: phase)
                        : 0

                    Circle()
                        .fill(Theme.heroGradient)
                        .frame(width: 10, height: 10)
                        .offset(y: visible ? offset : 0)
                        .opacity(visible ? 1 : 0)
                }
            }
        }
    }
}
