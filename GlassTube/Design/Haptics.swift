//
//  Haptics.swift
//  GlassTube
//
//  Thin wrapper over UIKit haptics so every spring interaction gets a
//  matching tactile cue.
//

import UIKit

enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let notification = UINotificationFeedbackGenerator()
    private static let selectionGen = UISelectionFeedbackGenerator()

    static func tap()    { light.impactOccurred(intensity: 0.8) }
    static func thump()  { medium.impactOccurred(intensity: 1.0) }
    static func tick()   { rigid.impactOccurred(intensity: 0.5) }
    static func select() { selectionGen.selectionChanged() }
    static func yay()    { notification.notificationOccurred(.success) }
}
