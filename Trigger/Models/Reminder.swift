import Foundation

struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String
    var createdAt: Date
    var remindAt: Date
    var isCompleted: Bool = false
    var completedAt: Date?
    var xpEarned: Int = 0
    var notificationIdentifier: String
    var usedVoiceInput: Bool = false

    var timeUntilReminder: TimeInterval {
        remindAt.timeIntervalSince(Date())
    }

    var isOverdue: Bool {
        !isCompleted && remindAt < Date()
    }

    var formattedTimeRemaining: String {
        let interval = timeUntilReminder
        if interval <= 0 { return isCompleted ? "Erledigt" : "Überfällig" }
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "In \(hours)h \(minutes)m"
        } else {
            return "In \(minutes)m"
        }
    }

    var formattedCompletedAgo: String {
        guard let completed = completedAt else { return "" }
        let interval = Date().timeIntervalSince(completed)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 { return "Vor \(hours)h" }
        if minutes > 0 { return "Vor \(minutes)m" }
        return "Gerade eben"
    }
}
