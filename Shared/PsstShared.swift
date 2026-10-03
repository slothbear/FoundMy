import Foundation

/// Values shared by the iPhone app, the watch app, and the watch Control Center button.
enum PsstShared {
    static let appGroup = "group.com.morganthall.psst"
    static let controlKind = "com.morganthall.psst.control"

    /// How long the iPhone chirps before giving up on its own.
    static let maxDuration: TimeInterval = 60

    enum Key {
        static let command = "command"
        static let playing = "playing"
        static let startedAt = "startedAt"
    }

    enum Command {
        static let start = "start"
        static let stop = "stop"
    }

    /// The iPhone's current state, as sent to the watch.
    static func payload(playing: Bool, startedAt: Date?) -> [String: Any] {
        var payload: [String: Any] = [Key.playing: playing]
        if let startedAt {
            payload[Key.startedAt] = startedAt
        }
        return payload
    }
}
