import UserNotifications
import Foundation

class NotificationService: NSObject {
    static let shared = NotificationService()

    private let categoryId = "TRIGGER_REMINDER"

    // MARK: - Setup

    func setup() {
        registerCategories()
    }

    private func registerCategories() {
        let doneAction = UNNotificationAction(
            identifier: "DONE",
            title: "✓ Erledigt",
            options: [.foreground]
        )
        let snooze1h = UNNotificationAction(
            identifier: "SNOOZE_1H",
            title: "⏰ +1 Stunde",
            options: []
        )
        let snooze3h = UNNotificationAction(
            identifier: "SNOOZE_3H",
            title: "⏰ +3 Stunden",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: categoryId,
            actions: [doneAction, snooze1h, snooze3h],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Permissions

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Schedule

    func schedule(reminder: Reminder) async {
        let content = UNMutableNotificationContent()
        content.title = "⚡ Trigger"
        content.body = reminder.text
        content.sound = .default
        content.categoryIdentifier = categoryId
        content.badge = 1
        content.userInfo = ["reminderId": reminder.id.uuidString]

        // Motivational subtitle
        let subtitles = [
            "Dein Gedanke wartet auf dich!",
            "Zeit, das zu erledigen 💪",
            "Du hast das gesetzt – pack es an!",
            "Dein zukünftiges Ich dankt dir.",
            "Der richtige Moment ist jetzt!",
        ]
        content.subtitle = subtitles.randomElement() ?? subtitles[0]

        let fireDate = reminder.remindAt
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(
            identifier: reminder.notificationIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Notification scheduling error: \(error)")
        }
    }

    // MARK: - Cancel

    func cancel(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
