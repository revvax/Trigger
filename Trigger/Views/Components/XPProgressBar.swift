import SwiftUI

struct XPProgressBar: View {
    let stats: UserStats
    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                // Level badge
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.triggerOrange)
                    Text("Lv.\(stats.level)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(Color.triggerOrange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.triggerOrange.opacity(0.12))
                .clipShape(Capsule())

                Text(stats.levelTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.triggerLightGray)
                    .padding(.leading, 4)

                Spacer()

                Text("\(stats.totalXP) XP")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.triggerDarkWhite)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.triggerMediumGray)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient.triggerOrangeGradient)
                        .frame(width: geo.size.width * animatedProgress, height: 8)

                    // Shine
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: geo.size.width * animatedProgress * 0.5, height: 3)
                        .offset(y: -1)
                        .mask(
                            RoundedRectangle(cornerRadius: 4)
                                .frame(width: geo.size.width * animatedProgress, height: 8)
                        )
                }
            }
            .frame(height: 8)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                    animatedProgress = stats.levelProgress
                }
            }
            .onChange(of: stats.levelProgress) { _, newVal in
                withAnimation(.spring(response: 0.6)) {
                    animatedProgress = newVal
                }
            }

            HStack {
                Text("\(stats.xpForCurrentLevel) XP")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(Color.triggerLightGray.opacity(0.6))
                Spacer()
                Text("\(stats.xpForNextLevel) XP")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(Color.triggerLightGray.opacity(0.6))
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

// MARK: - Streak Card

struct StreakCard: View {
    let streak: Int
    let longest: Int
    @State private var pulsing: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.orange)
                        .scaleEffect(pulsing ? 1.1 : 1.0)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                pulsing = true
                            }
                        }
                    Text("\(streak)")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(Color.triggerDarkWhite)
                }
                Text("Tage Streak")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.triggerLightGray)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.triggerCardBorder)
                .frame(width: 0.5)
                .padding(.vertical, 16)

            VStack(spacing: 4) {
                Text("\(longest)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(Color.triggerDarkWhite)
                Text("Rekord")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.triggerLightGray)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(Color.triggerCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.triggerCardBorder, lineWidth: 0.5)
        )
    }
}
