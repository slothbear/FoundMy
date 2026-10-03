import AVFoundation
import os

/// A repeating "psst": two short blips of a sine tone, then silence until the
/// next period.
struct ChirpPattern: Equatable {
    var frequency: Double
    var amplitude: Double
    var period: TimeInterval
    /// When set, the second blip of each chirp uses this pitch instead.
    var secondFrequency: Double? = nil

    static let blipLength = 0.07
    static let blipGap = 0.05

    func sample(at time: Double) -> Float {
        let t = time.truncatingRemainder(dividingBy: period)
        let secondStart = Self.blipLength + Self.blipGap
        let local: Double
        let pitch: Double
        if t < Self.blipLength {
            local = t
            pitch = frequency
        } else if t >= secondStart && t < secondStart + Self.blipLength {
            local = t - secondStart
            pitch = secondFrequency ?? frequency
        } else {
            return 0
        }
        // Raised-cosine envelope so each blip starts and ends without a click.
        let envelope = 0.5 - 0.5 * cos(2 * .pi * local / Self.blipLength)
        return Float(amplitude * envelope * sin(2 * .pi * pitch * local))
    }
}

/// Generates chirps live, so the pitch can be anything the tuner picks.
final class ToneEngine {
    private let engine = AVAudioEngine()
    private let pending = OSAllocatedUnfairLock<ChirpPattern?>(initialState: nil)
    private var isSetUp = false

    // Touched only on the audio render thread.
    private var renderPattern: ChirpPattern?
    private var time: Double = 0

    var isRunning: Bool { engine.isRunning }

    func play(_ pattern: ChirpPattern) throws {
        update(pattern)
        guard !engine.isRunning else { return }
        let session = AVAudioSession.sharedInstance()
        // .playback plays even with the ring/silent switch set to silent, and
        // mixing with others lets the app start audio while in the background.
        try session.setCategory(.playback, options: [.mixWithOthers])
        try session.setActive(true)
        setUpIfNeeded()
        try engine.start()
    }

    func update(_ pattern: ChirpPattern) {
        pending.withLock { $0 = pattern }
    }

    func stop() {
        engine.stop()
        pending.withLock { $0 = nil }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func setUpIfNeeded() {
        guard !isSetUp else { return }
        isSetUp = true

        var sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        if sampleRate <= 0 { sampleRate = 48_000 }
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let step = 1 / sampleRate

        let source = AVAudioSourceNode(format: format) { [unowned self] _, _, frameCount, bufferList in
            // Never block the audio thread; if the lock is busy, keep the last pattern.
            if let latest = self.pending.withLockIfAvailable({ $0 }) {
                if self.renderPattern == nil && latest != nil {
                    self.time = 0 // start each run with a chirp, not a pause
                }
                self.renderPattern = latest
            }
            let pattern = self.renderPattern
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            for frame in 0..<Int(frameCount) {
                let value = pattern?.sample(at: self.time) ?? 0
                self.time += step
                for buffer in buffers {
                    buffer.mData?.assumingMemoryBound(to: Float.self)[frame] = value
                }
            }
            return noErr
        }

        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: format)
    }
}
