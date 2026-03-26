import SwiftUI
import Foundation

@Observable
@MainActor
class AppStore {
    var reminders: [Reminder] = []
    var userStats: UserStats = UserStats()

    // UI feedback
    var showSuccessAnimation: Bool = false
    var lastXPGained: Int = 0
    var newlyUnlockedAchievement: Achievement?

    private let remindersKey = "trigger_reminders_v1"
    private let statsKey = "trigger_user_stats_v1"

    init() {
        loadData()
        updateStreakForToday()
    }

    // MARK: - Reminder Actions

    func addReminder(text: String, remindAt: Date, usedVoice: Bool = false) {
        let notificationId = UUID().uuidString
        let reminder = Reminder(
            text: text,
            createdAt: Date(),
            remindAt: remindAt,
            notificationIdentifier: notificationId,
            usedVoiceInput: usedVoice
        )
        reminders.insert(reminder, at: 0)

        // XP
        let xp = 10
        userStats.totalXP += xp
        userStats.totalRemindersCreated += 1
        if usedVoice { userStats.totalVoiceReminders += 1 }
        lastXPGained = xp
        showSuccessAnimation = true

        checkAchievements()
        saveData()

        Task {
            await NotificationService.shared.schedule(reminder: reminder)
        }
    }

    func completeReminder(_ reminder: Reminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }

        let now = Date()
        let onTime = now.timeIntervalSince(reminder.remindAt) < 3600 // within 1h
        let xp = onTime ? 25 : 15

        reminders[index].isCompleted = true
        reminders[index].completedAt = now
        reminders[index].xpEarned = xp

        userStats.totalXP += xp
        userStats.totalRemindersCompleted += 1
        lastXPGained = xp
        showSuccessAnimation = true

        checkAchievements()
        saveData()

        NotificationService.shared.cancel(identifier: reminder.notificationIdentifier)
    }

    func deleteReminder(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        NotificationService.shared.cancel(identifier: reminder.notificationIdentifier)
        saveData()
    }

    func snoozeReminder(_ reminder: Reminder, hours: Double) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        let newTime = Date().addingTimeInterval(hours * 3600)
        reminders[index].remindAt = newTime
        NotificationService.shared.cancel(identifier: reminder.notificationIdentifier)
        let updated = reminders[index]
        Task {
            await NotificationService.shared.schedule(reminder: updated)
        }
        saveData()
    }

    // MARK: - Computed

    var pendingReminders: [Reminder] {
        reminders.filter { !$0.isCompleted }.sorted { $0.remindAt < $1.remindAt }
    }

    var completedReminders: [Reminder] {
        reminders.filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
            .prefix(20)
            .map { $0 }
    }

    // MARK: - Streak

    private func updateStreakForToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastActive = userStats.lastActiveDate {
            let lastDay = calendar.startOfDay(for: lastActive)
            let diff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            switch diff {
            case 0: break // same day
            case 1:
                userStats.currentStreak += 1
                userStats.longestStreak = max(userStats.currentStreak, userStats.longestStreak)
            default:
                userStats.currentStreak = 1
            }
        } else {
            userStats.currentStreak = 1
            userStats.longestStreak = 1
        }

        userStats.lastActiveDate = Date()
        saveData()
    }

    // MARK: - Achievements

    private func checkAchievements() {
        let conditions: [(String, Bool)] = [
            ("first_trigger",  userStats.totalRemindersCreated >= 1),
            ("five_complete",  userStats.totalRemindersCompleted >= 5),
            ("25_complete",    userStats.totalRemindersCompleted >= 25),
            ("streak_3",       userStats.currentStreak >= 3),
            ("streak_7",       userStats.currentStreak >= 7),
            ("streak_30",      userStats.currentStreak >= 30),
            ("voice_5",        userStats.totalVoiceReminders >= 5),
            ("level_5",        userStats.level >= 5),
            ("level_10",       userStats.level >= 10),
        ]

        for (key, condition) in conditions {
            if condition, let idx = userStats.achievements.firstIndex(where: { $0.key == key }),
               !userStats.achievements[idx].isUnlocked {
                userStats.achievements[idx].unlockedAt = Date()
                newlyUnlockedAchievement = userStats.achievements[idx]
                userStats.totalXP += 50 // bonus XP for achievement
            }
        }
    }

    // MARK: - Persistence

    func saveData() {
        if let encoded = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(encoded, forKey: remindersKey)
        }
        if let encoded = try? JSONEncoder().encode(userStats) {
            UserDefaults.standard.set(encoded, forKey: statsKey)
        }
    }

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: remindersKey),
           let decoded = try? JSONDecoder().decode([Reminder].self, from: data) {
            reminders = decoded
        }
        if let data = UserDefaults.standard.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(UserStats.self, from: data) {
            userStats = decoded
            // Merge any new achievements from the static list
            let existingKeys = Set(userStats.achievements.map { $0.key })
            let newOnes = Achievement.all.filter { !existingKeys.contains($0.key) }
            userStats.achievements.append(contentsOf: newOnes)
        }
    }
}
