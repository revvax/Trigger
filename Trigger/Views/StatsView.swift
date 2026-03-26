import SwiftUI

struct StatsView: View {
    @Environment(AppStore.self) private var store
    @State private var selectedAchievement: Achievement?

    var stats: UserStats { store.userStats }

    var body: some View {
        ZStack {
            Color.triggerBG.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dein Fortschritt")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundStyle(Color.triggerDarkWhite)
                            Text("Bleib dran — du schaffst das!")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.triggerLightGray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // XP Progress
                    XPProgressBar(stats: stats)
                        .padding(.horizontal, 16)

                    // Streak
                    StreakCard(streak: stats.currentStreak, longest: stats.longestStreak)
                        .padding(.horizontal, 16)

                    // Stats grid
                    statsGrid
                        .padding(.horizontal, 16)

                    // Achievements
                    achievementsSection
                        .padding(.horizontal, 16)

                    Spacer().frame(height: 100)
                }
            }
        }
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(achievement: achievement)
                .presentationDetents([.height(280)])
                .presentationBackground(Color.triggerCard)
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        let items: [(String, String, String, Color)] = [
            ("Gesetzt",   "\(stats.totalRemindersCreated)",  "bolt.fill",        Color.triggerOrange),
            ("Erledigt",  "\(stats.totalRemindersCompleted)", "checkmark.circle.fill", Color.triggerSuccess),
            ("Quote",     "\(Int(stats.completionRate * 100))%", "chart.pie.fill", Color.blue),
            ("Sprach-🎤", "\(stats.totalVoiceReminders)",   "mic.fill",         Color.purple),
        ]

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(items, id: \.0) { item in
                StatCell(title: item.0, value: item.1, icon: item.2, color: item.3)
            }
        }
    }

    // MARK: - Achievements

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.triggerDarkWhite)
                Spacer()
                let unlocked = stats.achievements.filter { $0.isUnlocked }.count
                Text("\(unlocked)/\(stats.achievements.count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.triggerOrange)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(stats.achievements) { achievement in
                    AchievementBadge(achievement: achievement)
                        .onTapGesture {
                            HapticManager.light()
                            selectedAchievement = achievement
                        }
                }
            }
        }
        .padding(16)
        .background(Color.triggerCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.triggerCardBorder, lineWidth: 0.5)
        )
    }
}

// MARK: - Stat Cell

struct StatCell: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(Color.triggerDarkWhite)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.triggerLightGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.triggerCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.triggerCardBorder, lineWidth: 0.5)
        )
    }
}

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let achievement: Achievement
    @State private var shimmer: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked
                          ? Color.triggerOrange.opacity(0.18)
                          : Color.triggerMediumGray.opacity(0.3))
                    .frame(width: 52, height: 52)

                Image(systemName: achievement.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        achievement.isUnlocked ? Color.triggerOrange : Color.triggerLightGray.opacity(0.3)
                    )

                if achievement.isUnlocked {
                    Circle()
                        .strokeBorder(
                            LinearGradient.triggerOrangeGradient,
                            lineWidth: 2
                        )
                        .frame(width: 52, height: 52)
                        .opacity(shimmer ? 0.8 : 0.4)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                shimmer = true
                            }
                        }
                }
            }

            Text(achievement.title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(
                    achievement.isUnlocked ? Color.triggerDarkWhite : Color.triggerLightGray.opacity(0.4)
                )
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 52)
        }
    }
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Handle
            Capsule()
                .fill(Color.triggerMediumGray)
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            ZStack {
                Circle()
                    .fill(achievement.isUnlocked
                          ? Color.triggerOrange.opacity(0.15)
                          : Color.triggerMediumGray.opacity(0.3))
                    .frame(width: 80, height: 80)

                Image(systemName: achievement.icon)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(
                        achievement.isUnlocked ? Color.triggerOrange : Color.triggerLightGray.opacity(0.4)
                    )
            }

            VStack(spacing: 8) {
                Text(achievement.title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Color.triggerDarkWhite)

                Text(achievement.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.triggerLightGray)
                    .multilineTextAlignment(.center)

                if let date = achievement.unlockedAt {
                    Text("Freigeschaltet \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.triggerOrange.opacity(0.8))
                } else {
                    Text("Noch nicht freigeschaltet")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.triggerLightGray.opacity(0.6))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.triggerCard)
    }
}
