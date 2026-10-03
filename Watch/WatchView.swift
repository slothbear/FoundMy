import SwiftUI

struct WatchView: View {
    @ObservedObject private var link = WatchLink.shared
    @State private var isSending = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 10) {
            Button(action: toggle) {
                Image(systemName: link.isPlaying ? "stop.fill" : "speaker.wave.1.fill")
                    .font(.system(size: 36))
                    .frame(width: 90, height: 90)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .tint(link.isPlaying ? .red : .accentColor)
            .disabled(isSending)

            Text(status)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(errorMessage == nil ? .secondary : .primary)
        }
        .onAppear { link.refresh() }
    }

    private var status: String {
        if let errorMessage { return errorMessage }
        if isSending { return "Asking your iPhone…" }
        return link.isPlaying ? "Chirping. Tap to stop." : "Tap to make your iPhone chirp."
    }

    private func toggle() {
        isSending = true
        errorMessage = nil
        Task {
            do {
                try await link.setPlaying(!link.isPlaying)
            } catch {
                errorMessage = error.localizedDescription
            }
            isSending = false
        }
    }
}

#Preview {
    WatchView()
}
