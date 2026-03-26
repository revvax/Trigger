import Foundation

struct Achievement: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var key: String
    var title: String
    var description: String
    var icon: String
    var unlockedAt: Date?
    var isUnlocked: Bool { unlockedAt != nil }
}

struct UserStats: Codable {
    var totalXP: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastActiveDate: Date?
    var totalRemindersCreated: Int = 0
    var totalRemindersCompleted: Int = 0
    var totalVoiceReminders: Int = 0
    var achievements: [Achievement] = Achievement.all

    var level: Int {
        let thresholds = [0, 100, 250, 500, 1000, 2000, 3500, 5500, 8000, 12000]
        for (i, threshold) in thresholds.enumerated().reversed() {
            if totalXP >= threshold { return i + 1 }
        }
        return 1
    }

    var xpForCurrentLevel: Int {
        let thresholds = [0, 100, 250, 500, 1000, 2000, 3500, 5500, 8000, 12000]
        let lvl = min(level - 1, thresholds.count - 1)
        return thresholds[lvl]
    }

    var xpForNextLevel: Int {
        let thresholds = [100, 250, 500, 1000, 2000, 3500, 5500, 8000, 12000, 20000]
        let lvl = min(level - 1, thresholds.count - 1)
        return thresholds[lvl]
    }

    var levelProgress: Double {
        let current = Double(totalXP - xpForCurrentLevel)
        let needed = Double(xpForNextLevel - xpForCurrentLevel)
        guard needed > 0 else { return 1.0 }
        return max(0, min(1, current / needed))
    }

    var levelTitle: String {
        let titles = ["Starter", "Denker", "Macher", "Fokus-Fan", "Flow-Master",
                      "Gedanken-Guru", "Memory-Pro", "Trigger-Elite", "ADHS-Hero", "Legende"]
        let idx = min(level - 1, titles.count - 1)
        return titles[idx]
    }

    var completionRate: Double {
        guard totalRemindersCreated > 0 else { return 0 }
        return Double(totalRemindersCompleted) / Double(totalRemindersCreated)
    }
}

extension Achievement {
    static let all: [Achievement] = [
        Achievement(key: "first_trigger",  title: "Erster Trigger",   description: "Erste Erinnerung gesetzt",       icon: "bolt.fill"),
        Achievement(key: "five_complete",  title: "Auf Kurs",         description: "5 Erinnerungen erledigt",        icon: "checkmark.seal.fill"),
        Achievement(key: "25_complete",    title: "Memory Master",    description: "25 Erinnerungen erledigt",       icon: "brain.head.profile"),
        Achievement(key: "streak_3",       title: "3-Tage Streak",    description: "3 Tage in Folge aktiv",          icon: "flame.fill"),
        Achievement(key: "streak_7",       title: "Woche durch",      description: "7 Tage Streak",                  icon: "star.fill"),
        Achievement(key: "streak_30",      title: "ADHS-Hero",        description: "30 Tage Streak",                 icon: "trophy.fill"),
        Achievement(key: "voice_5",        title: "Voice Star",       description: "5x Spracheingabe genutzt",       icon: "mic.fill"),
        Achievement(key: "quick_draw",     title: "Quick Draw",       description: "Erinnerung in unter 5 Sek.",    icon: "timer"),
        Achievement(key: "level_5",        title: "Flow-Master",      description: "Level 5 erreicht",               icon: "chart.line.uptrend.xyaxis"),
        Achievement(key: "level_10",       title: "Legende",          description: "Level 10 – Maximum erreicht",   icon: "crown.fill"),
    ]
}
