import Foundation

/// What the watch last heard from the iPhone, stored where both the watch app
/// and the Control Center button can read it.
enum PsstState {
    private static let defaults = UserDefaults(suiteName: PsstShared.appGroup) ?? .standard
    private static let startedAtKey = "startedAt"

    static var startedAt: Date? {
        defaults.object(forKey: startedAtKey) as? Date
    }

    /// Expires on its own once the iPhone would have timed out, so a missed
    /// "stopped" message can't leave the button stuck on.
    static var isPlaying: Bool {
        guard let startedAt else { return false }
        return Date().timeIntervalSince(startedAt) < PsstShared.maxDuration + 2
    }

    static func record(playing: Bool, startedAt: Date?) {
        if playing {
            defaults.set(startedAt ?? Date(), forKey: startedAtKey)
        } else {
            defaults.removeObject(forKey: startedAtKey)
        }
    }
}
