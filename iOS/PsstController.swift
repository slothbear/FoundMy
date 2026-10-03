import AVFoundation
import Foundation

/// Runs one Psst: plays the chirp, escalates it, and stops it.
/// Used on the main thread only.
final class PsstController: ObservableObject {
    static let shared = PsstController()

    enum StopReason {
        case user, remote, pickedUp, timedOut, interrupted
    }

    @Published private(set) var isPlaying = false
    @Published private(set) var stageIndex = 0
    @Published private(set) var isPreviewing = false
    private(set) var startedAt: Date?

    private let tone = ToneEngine()
    private let pickup = PickupDetector()
    private var ticker: Timer?

    private init() {
        // A phone call or alarm takes the speaker; don't fight it.
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .began else { return }
            self?.stop(.interrupted)
            self?.stopPreview()
        }
    }

    func start(stopOnPickup: Bool) {
        guard !isPlaying else { return }
        stopPreview()
        startedAt = Date()
        stageIndex = 0
        do {
            try tone.play(currentPattern())
        } catch {
            startedAt = nil
            return
        }
        isPlaying = true
        ticker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
        if stopOnPickup {
            pickup.start { [weak self] in self?.stop(.pickedUp) }
        }
        Notifier.shared.showChirping()
        PhoneLink.shared.publish(playing: true, startedAt: startedAt)
    }

    func stop(_ reason: StopReason) {
        guard isPlaying else { return }
        ticker?.invalidate()
        ticker = nil
        pickup.stop()
        tone.stop()
        isPlaying = false
        startedAt = nil
        stageIndex = 0
        Notifier.shared.clearChirping()
        if reason == .timedOut {
            Notifier.shared.showGaveUp()
        }
        PhoneLink.shared.publish(playing: false, startedAt: nil)
    }

    private func tick() {
        guard let startedAt else { return }
        let elapsed = Date().timeIntervalSince(startedAt)
        if elapsed >= PsstShared.maxDuration {
            stop(.timedOut)
            return
        }
        let index = Escalation.stageIndex(at: elapsed)
        if index != stageIndex {
            stageIndex = index
            tone.update(currentPattern())
        }
    }

    private func currentPattern() -> ChirpPattern {
        Escalation.stages[stageIndex].pattern(pitch: PsstSettings.pitch, startLoudness: PsstSettings.startLoudness)
    }

    // MARK: - Tuner preview

    func preview(pitch: Double, loudness: Double) {
        guard !isPlaying else { return }
        let pattern = ChirpPattern(frequency: pitch, amplitude: loudness, period: 1.0)
        if isPreviewing {
            tone.update(pattern)
        } else {
            try? tone.play(pattern)
            isPreviewing = tone.isRunning
        }
    }

    func stopPreview() {
        guard isPreviewing else { return }
        tone.stop()
        isPreviewing = false
    }
}
