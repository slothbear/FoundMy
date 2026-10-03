import AppIntents
import SwiftUI
import WidgetKit

/// The on/off button in the watch's Control Center.
struct PsstControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: PsstShared.controlKind, provider: Provider()) { isPlaying in
            ControlWidgetToggle("Psst", isOn: isPlaying, action: SetPsstIntent()) { isOn in
                Label(isOn ? "Chirping" : "Psst", systemImage: isOn ? "speaker.wave.2.fill" : "speaker.wave.1")
            }
        }
        .displayName("Psst")
        .description("Make your iPhone chirp quietly.")
    }

    struct Provider: ControlValueProvider {
        var previewValue: Bool { false }

        func currentValue() async throws -> Bool {
            PsstState.isPlaying
        }
    }
}

@main
struct PsstControls: WidgetBundle {
    var body: some Widget {
        PsstControl()
    }
}
