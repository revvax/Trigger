import SwiftUI
import UserNotifications

@main
struct TriggerApp: App {
    @State private var store = AppStore()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .preferredColorScheme(.dark)
                .onAppear {
                    Task {
                        await NotificationService.shared.requestPermission()
                        NotificationService.shared.setup()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .reminderCompleted)) { notification in
                    if let idString = notification.userInfo?["reminderId"] as? String,
                       let id = UUID(uuidString: idString),
                       let reminder = store.reminders.first(where: { $0.id == id }) {
                        store.completeReminder(reminder)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .reminderSnoozed)) { notification in
                    if let idString = notification.userInfo?["reminderId"] as? String,
                       let id = UUID(uuidString: idString),
                       let hours = notification.userInfo?["hours"] as? Double,
                       let reminder = store.reminders.first(where: { $0.id == id }) {
                        store.snoozeReminder(reminder, hours: hours)
                    }
                }
        }
    }
}

// MARK: - AppDelegate for notification responses

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let reminderId = userInfo["reminderId"] as? String ?? ""

        switch response.actionIdentifier {
        case "DONE":
            NotificationCenter.default.post(
                name: .reminderCompleted,
                object: nil,
                userInfo: ["reminderId": reminderId]
            )
        case "SNOOZE_1H":
            NotificationCenter.default.post(
                name: .reminderSnoozed,
                object: nil,
                userInfo: ["reminderId": reminderId, "hours": 1.0]
            )
        case "SNOOZE_3H":
            NotificationCenter.default.post(
                name: .reminderSnoozed,
                object: nil,
                userInfo: ["reminderId": reminderId, "hours": 3.0]
            )
        default:
            break
        }
        completionHandler()
    }
}

// MARK: - Notification names

extension Notification.Name {
    static let reminderCompleted = Notification.Name("trigger.reminderCompleted")
    static let reminderSnoozed   = Notification.Name("trigger.reminderSnoozed")
}
