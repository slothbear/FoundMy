import SwiftUI

@main
struct PsstWatchApp: App {
    init() {
        WatchLink.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            WatchView()
        }
    }
}
