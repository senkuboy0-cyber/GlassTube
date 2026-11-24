//
//  Spring.swift
//  GlassTube
//
//  Spring presets plus a real damped-harmonic-oscillator solver. The solver
//  is used to render animations from actual physics (splash dots) and to
//  project gesture release velocity into a settle target (momentum).
//

import SwiftUI

/// Tuned spring presets used across the app.
enum Spring {
    /// Tight, quick settle — taps, selection pills, control presses.
    static let snappy  = Animation.spring(response: 0.30, dampingFraction: 0.72, blendDuration: 0.20)
    /// A little overshoot — entrances and playful moments.
    static let bouncy  = Animation.spring(response: 0.42, dampingFraction: 0.60, blendDuration: 0.25)
    /// Slow and calm — large surfaces, layout shifts, feed reloads.
    static let gentle  = Animation.spring(response: 0.55, dampingFraction: 0.85, blendDuration: 0.30)
    /// Grand, cinematic motion — player slide-ups, splash hand-off.
    static let opulent = Animation.spring(response: 0.68, dampingFraction: 0.76, blendDuration: 0.40)
}

/// Analytic damped harmonic oscillator: x(t) for a mass-spring-damper system.
enum SpringPhysics {

    /// Position of an oscillator that starts at `x0` with velocity `v0`
    /// and settles toward equilibrium zero, sampled at time `t` (seconds).
    static func position(
        x0: CGFloat,
        v0: CGFloat,
        stiffness: CGFloat = 170,
        damping: CGFloat = 16,
        t: CGFloat
    ) -> CGFloat {
        let omega = stiffness.squareRoot()
        let zeta = damping / (2 * omega)

        if zeta >= 1 {
            // Over/critically damped — two real roots.
            let z = max(zeta, 1.0001)
            let root = (z * z - 1).squareRoot()
            let s1 = -omega * (z - root)
            let s2 = -omega * (z + root)
            let c1 = (v0 - s2 * x0) / (s1 - s2)
            let c2 = x0 - c1
            return c1 * CGFloat(Foundation.exp(Double(s1 * t)))
                + c2 * CGFloat(Foundation.exp(Double(s2 * t)))
        }

        // Underdamped — the fun one.
        let omegaD = omega * (1 - zeta * zeta).squareRoot()
        let decay = CGFloat(Foundation.exp(Double(-zeta * omega * t)))
        let cosT = CGFloat(Foundation.cos(Double(omegaD * t)))
        let sinT = CGFloat(Foundation.sin(Double(omegaD * t)))
        return decay * (x0 * cosT + ((v0 + zeta * omega * x0) / omegaD) * sinT)
    }

    /// Momentum projection — where a flung surface should land.
    /// Mirrors the deceleration feel of UIScrollView.
    static func momentumTarget(
        from position: CGFloat,
        velocity: CGFloat,
        influence: CGFloat = 0.55
    ) -> CGFloat {
        position + velocity * influence
    }

    /// iOS-style rubber band: resistance as a value is pulled past `limit`.
    static func rubberBand(_ value: CGFloat, limit: CGFloat, dimension: CGFloat) -> CGFloat {
        guard abs(value) > 0 else { return value }
        let limit = max(limit, 1)
        if abs(value) <= limit { return value }
        let sign: CGFloat = value > 0 ? 1 : -1
        let excess = abs(value) - limit
        let dim = max(dimension, 1)
        let rubber = (1.0 - 1.0 / (excess / dim * 0.55 + 1.0)) * dim
        return limit * sign + rubber * sign
    }
}
