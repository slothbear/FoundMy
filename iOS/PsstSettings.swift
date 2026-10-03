import Foundation

enum PsstSettings {
    static let pitchKey = "pitchHz"
    static let loudnessKey = "startLoudness"
    static let stopOnPickupKey = "stopOnPickup"

    static let defaultPitch = 10_000.0
    static let defaultLoudness = 0.2

    static let pitchRange = 4_000.0...16_000.0
    static let loudnessRange = 0.05...0.5

    static func register() {
        UserDefaults.standard.register(defaults: [
            pitchKey: defaultPitch,
            loudnessKey: defaultLoudness,
            stopOnPickupKey: true,
        ])
    }

    static var pitch: Double { UserDefaults.standard.double(forKey: pitchKey) }
    static var startLoudness: Double { UserDefaults.standard.double(forKey: loudnessKey) }
    static var stopOnPickup: Bool { UserDefaults.standard.bool(forKey: stopOnPickupKey) }
}
