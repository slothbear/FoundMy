import UserNotifications

/// Lock-screen notifications: a Stop button while chirping, and a heads-up
/// (which also reaches the watch) if Psst gives up.
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Notifier()

    private let center = UNUserNotificationCenter.current()
    private let chirpingID = "psst.chirping"
    private let gaveUpID = "psst.gaveUp"
    private let chirpingCategory = "psst.chirping"
    private let stopAction = "psst.stop"

    func setUp() {
        center.delegate = self
        let stop = UNNotificationAction(identifier: stopAction, title: "Stop")
        center.setNotificationCategories([
            UNNotificationCategory(identifier: chirpingCategory, actions: [stop], intentIdentifiers: [])
        ])
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func showChirping() {
        let content = UNMutableNotificationContent()
        content.title = "Psst is chirping"
        content.body = "Touch and hold to stop it."
        content.categoryIdentifier = chirpingCategory
        // Silent and doesn't light the screen; it's just there to offer Stop.
        content.interruptionLevel = .passive
        center.add(UNNotificationRequest(identifier: chirpingID, content: content, trigger: nil))
    }

    func clearChirping() {
        center.removePendingNotificationRequests(withIdentifiers: [chirpingID])
        center.removeDeliveredNotifications(withIdentifiers: [chirpingID])
    }

    func showGaveUp() {
        let content = UNMutableNotificationContent()
        content.title = "Psst stopped"
        content.body = "Your iPhone chirped for a minute without being found. Find My can play a louder sound."
        content.sound = .default
        center.add(UNNotificationRequest(identifier: gaveUpID, content: content, trigger: nil))
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let isGaveUp = notification.request.identifier == gaveUpID
        completionHandler(isGaveUp ? [.banner, .list, .sound] : [.list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Tapping Stop, or tapping the notification itself, means it's found.
        if response.notification.request.identifier == chirpingID {
            DispatchQueue.main.async {
                PsstController.shared.stop(.user)
            }
        }
        completionHandler()
    }
}
