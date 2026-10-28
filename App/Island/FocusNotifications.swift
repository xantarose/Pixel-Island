import Foundation
import UserNotifications

/// A local notification when the focus timer ends. Local only: no push
/// server, no entitlement, works with any signing certificate.
enum FocusNotifications {
    private static let identifier = "pixelisland.focus.done"

    static func schedule(at date: Date, petName: String) async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return }

        let seconds = date.timeIntervalSinceNow
        guard seconds > 1 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Фокус окончен ✨"
        content.body = "\(petName) просыпается и гордится тобой. Перерыв!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
