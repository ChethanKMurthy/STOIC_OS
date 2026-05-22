import Foundation
import UserNotifications

/// Best-effort hourly check-in reminders via macOS notifications.
///
/// True always-on prompting (when the app is fully quit) needs the background
/// scheduler helper — a later phase. These fire while the app is running or
/// backgrounded.
enum NotificationManager {

    private static let hours = Array(9...21)

    static func requestAndSchedule() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            schedule()
        }
    }

    private static func schedule() {
        let center = UNUserNotificationCenter.current()
        let ids = hours.map { "stoic.hourly.\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        for hour in hours {
            var components = DateComponents()
            components.hour = hour
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            let content = UNMutableNotificationContent()
            content.title = "STOIC OS"
            content.body = "How was the last hour spent?"

            let request = UNNotificationRequest(identifier: "stoic.hourly.\(hour)",
                                                content: content,
                                                trigger: trigger)
            center.add(request)
        }
    }
}
