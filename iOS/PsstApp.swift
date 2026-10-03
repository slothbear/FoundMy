import SwiftUI

@main
struct PsstApp: App {
    init() {
        // This also runs when the watch wakes the app in the background,
        // so everything needed to answer the watch is set up here.
        PsstSettings.register()
        Notifier.shared.setUp()
        PhoneLink.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
