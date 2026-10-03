import AppIntents

/// Starts or stops the chirp. Used by the Control Center button.
struct SetPsstIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Psst"

    // Only the watch app can talk to the iPhone, so the button runs this in
    // the app, which then shows the current state and a Stop button.
    static let openAppWhenRun: Bool = true

    @Parameter(title: "Chirping")
    var value: Bool

    func perform() async throws -> some IntentResult {
        try await WatchLink.shared.setPlaying(value)
        return .result()
    }
}
