import Foundation
import WatchConnectivity
import WidgetKit

/// The watch side of the watch↔iPhone connection.
final class WatchLink: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchLink()

    @Published private(set) var isPlaying = PsstState.isPlaying
    private var expiryTask: Task<Void, Never>?

    enum LinkError: LocalizedError {
        case unreachable

        var errorDescription: String? {
            "Can't reach your iPhone. Make sure it's nearby with Bluetooth or Wi-Fi on."
        }
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        if session.delegate == nil {
            session.delegate = self
        }
        if session.activationState != .activated {
            session.activate()
        }
    }

    /// Asks the iPhone to start or stop chirping. Returns whether it is chirping now.
    @discardableResult
    func setPlaying(_ playing: Bool) async throws -> Bool {
        activate()
        let session = WCSession.default

        // Activation and reachability can take a moment right after launch.
        let deadline = Date().addingTimeInterval(3)
        while !(session.activationState == .activated && session.isReachable) && Date() < deadline {
            try await Task.sleep(for: .milliseconds(150))
        }
        guard session.activationState == .activated, session.isReachable else {
            throw LinkError.unreachable
        }

        let message = [PsstShared.Key.command: playing ? PsstShared.Command.start : PsstShared.Command.stop]
        let reply: [String: Any] = try await withCheckedThrowingContinuation { continuation in
            session.sendMessage(
                message,
                replyHandler: { continuation.resume(returning: $0) },
                errorHandler: { continuation.resume(throwing: $0) }
            )
        }
        apply(reply)
        return reply[PsstShared.Key.playing] as? Bool ?? false
    }

    /// Re-reads the stored state, e.g. after it may have expired.
    func refresh() {
        isPlaying = PsstState.isPlaying
        expiryTask?.cancel()
        guard isPlaying, let startedAt = PsstState.startedAt else { return }
        let remaining = PsstShared.maxDuration + 2 - Date().timeIntervalSince(startedAt)
        expiryTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(max(remaining, 0)))
            guard !Task.isCancelled else { return }
            self?.refresh()
            ControlCenter.shared.reloadControls(ofKind: PsstShared.controlKind)
        }
    }

    private func apply(_ payload: [String: Any]) {
        guard let playing = payload[PsstShared.Key.playing] as? Bool else { return }
        PsstState.record(playing: playing, startedAt: payload[PsstShared.Key.startedAt] as? Date)
        ControlCenter.shared.reloadControls(ofKind: PsstShared.controlKind)
        DispatchQueue.main.async {
            self.refresh()
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        if state == .activated {
            apply(session.receivedApplicationContext)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        apply(message)
    }
}
