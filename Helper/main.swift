import AppKit
import UserNotifications

// STOIC OS background helper — a login-item agent.
//
// Keeps hourly check-in reminders firing even when the main app is fully quit.
// On launch it schedules the hourly reminders and fires one test notification
// so the agent can be verified immediately.

private let checkInHours = Array(9...21)

private func scheduleHourlyReminders(_ center: UNUserNotificationCenter) {
    let ids = checkInHours.map { "stoic.hourly.\($0)" }
    center.removePendingNotificationRequests(withIdentifiers: ids)

    for hour in checkInHours {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "STOIC OS"
        content.body = "How was the last hour spent?"

        center.add(UNNotificationRequest(identifier: "stoic.hourly.\(hour)",
                                         content: content,
                                         trigger: trigger))
    }
}

private func fireBootNotification(_ center: UNUserNotificationCenter) {
    let content = UNMutableNotificationContent()
    content.title = "STOIC OS Helper"
    content.body = "Background helper online \u{2014} hourly reminders scheduled."
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
    center.add(UNNotificationRequest(identifier: "stoic.helper.boot",
                                     content: content,
                                     trigger: trigger))
}

let helper = NSApplication.shared
helper.setActivationPolicy(.accessory)

let center = UNUserNotificationCenter.current()
center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
    guard granted else { return }
    scheduleHourlyReminders(center)
    fireBootNotification(center)
}

helper.run()
