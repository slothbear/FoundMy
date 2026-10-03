import Foundation
import WatchConnectivity

/// The iPhone side of the watch↔iPhone connection.
final class PhoneLink: NSObject, WCSessionDelegate {
    static let shared = PhoneLink()

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Tells the watch whether Psst is chirping, so its button shows the truth
    /// even when the chirp stopped some other way (picked up, timed out).
    func publish(playing: Bool, startedAt: Date?) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
        let payload = PsstShared.payload(playing: playing, startedAt: startedAt)
        try? session.updateApplicationContext(payload)
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        let command = message[PsstShared.Key.command] as? String
        DispatchQueue.main.async {
            let controller = PsstController.shared
            switch command {
            case PsstShared.Command.start?:
                controller.start(stopOnPickup: PsstSettings.stopOnPickup)
            case PsstShared.Command.stop?:
                controller.stop(.remote)
            default:
                break
            }
            replyHandler(PsstShared.payload(playing: controller.isPlaying, startedAt: controller.startedAt))
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Happens when switching to a different watch.
        session.activate()
    }
}
