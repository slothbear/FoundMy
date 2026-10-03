import SwiftUI

struct ContentView: View {
    @ObservedObject private var controller = PsstController.shared
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(PsstSettings.pitchKey) private var pitch = PsstSettings.defaultPitch
    @AppStorage(PsstSettings.loudnessKey) private var loudness = PsstSettings.defaultLoudness
    @AppStorage(PsstSettings.stopOnPickupKey) private var stopOnPickup = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button(controller.isPlaying ? "Stop" : "Test the full sequence") {
                        if controller.isPlaying {
                            controller.stop(.user)
                        } else {
                            // You're holding the phone, so don't stop on pickup here.
                            controller.start(stopOnPickup: false)
                        }
                    }
                    if controller.isPlaying {
                        LabeledContent("Stage", value: Escalation.stages[controller.stageIndex].name)
                    }
                } footer: {
                    Text("Normally you'll start Psst from your watch's Control Center.")
                }

                Section {
                    Toggle("Listen", isOn: previewBinding)
                        .disabled(controller.isPlaying)
                    LabeledContent("Pitch", value: String(format: "%.2f kHz", pitch / 1000))
                    Slider(value: $pitch, in: PsstSettings.pitchRange, step: 250)
                } header: {
                    Text("Pitch")
                } footer: {
                    Text("Turn on Listen and slide until you can hear the chirp clearly but others in the room can't. Hearing for high pitches fades with age, so this is easiest to tune together.")
                }

                Section {
                    Slider(value: $loudness, in: PsstSettings.loudnessRange)
                } header: {
                    Text("Starting loudness")
                } footer: {
                    Text("Psst starts this loud, gets louder after 20 seconds, adds a lower, easier-to-hear tone after 40, and stops after a minute. It can't play louder than your iPhone's media volume.")
                }

                Section {
                    Toggle("Stop when I pick up my iPhone", isOn: $stopOnPickup)
                }
            }
            .navigationTitle("Psst")
            .onChange(of: pitch) { refreshPreview() }
            .onChange(of: loudness) { refreshPreview() }
            .onChange(of: scenePhase) {
                if scenePhase != .active { controller.stopPreview() }
            }
        }
    }

    private var previewBinding: Binding<Bool> {
        Binding(
            get: { controller.isPreviewing },
            set: { on in
                if on {
                    controller.preview(pitch: pitch, loudness: loudness)
                } else {
                    controller.stopPreview()
                }
            }
        )
    }

    private func refreshPreview() {
        if controller.isPreviewing {
            controller.preview(pitch: pitch, loudness: loudness)
        }
    }
}

#Preview {
    ContentView()
}
