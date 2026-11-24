//
//  FluidBackground.swift
//  GlassTube
//
//  Slow-moving gradient "blobs" behind the glass surfaces. Positions are
//  driven by real sine motion on a 30 Hz timeline, giving the UI a living,
//  fluid backdrop without GPU-heavy shaders.
//

import SwiftUI

private struct Blob: Identifiable {
    let id = UUID()
    let color: Color
    let radius: CGFloat
    let speed: Double
    let phase: Double
    let orbitX: CGFloat
    let orbitY: CGFloat
}

struct FluidBackground: View {
    var intensity: Double = 1

    private let blobs: [Blob] = [
        Blob(color: Theme.accent,     radius: 340, speed: 0.21, phase: 0.0, orbitX:  0.28, orbitY:  0.22),
        Blob(color: Theme.accentCool, radius: 300, speed: 0.16, phase: 2.1, orbitX: -0.24, orbitY: -0.18),
        Blob(color: Theme.accentHot,  radius: 260, speed: 0.13, phase: 4.2, orbitX:  0.18, orbitY: -0.26),
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                ZStack {
                    Theme.bgDeep

                    ForEach(blobs) { blob in
                        let x = geo.size.width / 2
                            + CGFloat(sin(t * blob.speed + blob.phase)) * geo.size.width * blob.orbitX
                        let y = geo.size.height / 2
                            + CGFloat(cos(t * blob.speed * 1.3 + blob.phase)) * geo.size.height * blob.orbitY

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [blob.color.opacity(0.45 * intensity), blob.color.opacity(0)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: blob.radius
                                )
                            )
                            .frame(width: blob.radius * 2, height: blob.radius * 2)
                            .position(x: x, y: y)
                            .blur(radius: 60)
                    }

                    // Vignette keeps content readable over the fluid layer.
                    RadialGradient(
                        colors: [.clear, Theme.bgDeep.opacity(0.78)],
                        center: .center,
                        startRadius: geo.size.width * 0.25,
                        endRadius: geo.size.width * 0.85
                    )
                }
            }
            .ignoresSafeArea()
        }
    }
}
