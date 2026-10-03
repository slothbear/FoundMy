import Foundation

/// One step of the chirp getting more insistent the longer it goes unanswered.
struct EscalationStage {
    let name: String
    let startsAt: TimeInterval
    /// Seconds from the start of one chirp to the next.
    let period: TimeInterval
    /// Multiplies the starting loudness, capped at full volume.
    let loudnessMultiplier: Double
    /// Adds a lower tone, which carries through cushions and is easier for
    /// everyone to hear.
    let addsLowTone: Bool

    func pattern(pitch: Double, startLoudness: Double) -> ChirpPattern {
        ChirpPattern(
            frequency: pitch,
            amplitude: min(1, startLoudness * loudnessMultiplier),
            period: period,
            secondFrequency: addsLowTone ? Escalation.lowToneHz : nil
        )
    }
}

enum Escalation {
    static let lowToneHz = 2_000.0

    static let stages = [
        EscalationStage(name: "Quiet", startsAt: 0, period: 2.0, loudnessMultiplier: 1, addsLowTone: false),
        EscalationStage(name: "Louder", startsAt: 20, period: 1.2, loudnessMultiplier: 2.5, addsLowTone: false),
        EscalationStage(name: "Loudest", startsAt: 40, period: 0.8, loudnessMultiplier: 20, addsLowTone: true),
    ]

    static func stageIndex(at elapsed: TimeInterval) -> Int {
        stages.lastIndex { elapsed >= $0.startsAt } ?? 0
    }
}
