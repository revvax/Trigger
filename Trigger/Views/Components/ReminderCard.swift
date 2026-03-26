import SwiftUI

struct ReminderCard: View {
    let reminder: Reminder
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onSnooze: (Double) -> Void

    @State private var showSnoozeMenu: Bool = false
    @State private var offset: CGFloat = 0
    @State private var isDragging: Bool = false

    var body: some View {
        ZStack {
            // Background action indicators
            HStack {
                // Complete (swipe right)
                ZStack {
                    Color.triggerSuccess
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 28, weight: .bold))
                        .padding(.leading, 24)
                }
                .frame(width: max(0, offset))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Spacer()

                // Delete (swipe left)
                ZStack {
                    Color.triggerDanger
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 22, weight: .bold))
                        .padding(.trailing, 24)
                }
                .frame(width: max(0, -offset))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Card content
            cardContent
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            offset = value.translation.width * 0.6
                        }
                        .onEnded { value in
                            isDragging = false
                            let threshold: CGFloat = 80
                            if value.translation.width > threshold {
                                HapticManager.success()
                                withAnimation(.spring()) { offset = 400 }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onComplete()
                                }
                            } else if value.translation.width < -threshold {
                                HapticManager.error()
                                withAnimation(.spring()) { offset = -400 }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onDelete()
                                }
                            } else {
                                withAnimation(.spring(response: 0.4)) { offset = 0 }
                            }
                        }
                )
        }
        .confirmationDialog("Snoozen um…", isPresented: $showSnoozeMenu) {
            Button("1 Stunde") { onSnooze(1) }
            Button("3 Stunden") { onSnooze(3) }
            Button("8 Stunden") { onSnooze(8) }
            Button("Abbrechen", role: .cancel) {}
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                // Icon
                ZStack {
                    Circle()
                        .fill(reminder.isOverdue ? Color.triggerDanger.opacity(0.15) : Color.triggerOrange.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: reminder.isOverdue ? "exclamationmark.triangle.fill" : "bolt.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(reminder.isOverdue ? Color.triggerDanger : Color.triggerOrange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.text)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.triggerDarkWhite)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        // Time remaining
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10, weight: .medium))
                            Text(reminder.formattedTimeRemaining)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(reminder.isOverdue ? Color.triggerDanger : Color.triggerOrange)

                        if reminder.usedVoiceInput {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.triggerLightGray)
                        }
                    }
                }

                Spacer()

                // Snooze button
                Button {
                    HapticManager.light()
                    showSnoozeMenu = true
                } label: {
                    Image(systemName: "alarm")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.triggerLightGray)
                        .padding(8)
                        .background(Color.triggerMediumGray.opacity(0.4))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            // Progress bar: time elapsed since creation
            let total = reminder.remindAt.timeIntervalSince(reminder.createdAt)
            let elapsed = Date().timeIntervalSince(reminder.createdAt)
            let progress = total > 0 ? min(max(elapsed / total, 0), 1) : 1

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.triggerMediumGray)
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(reminder.isOverdue ? Color.triggerDanger : Color.triggerOrange)
                        .frame(width: geo.size.width * progress, height: 3)
                        .animation(.linear(duration: 1), value: progress)
                }
            }
            .frame(height: 3)
        }
        .padding(16)
        .background(Color.triggerCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    reminder.isOverdue ? Color.triggerDanger.opacity(0.4) : Color.triggerCardBorder,
                    lineWidth: 0.5
                )
        )
    }
}

// MARK: - Completed Reminder Card

struct CompletedReminderCard: View {
    let reminder: Reminder

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.triggerSuccess.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.triggerSuccess)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.triggerLightGray)
                    .lineLimit(1)
                    .strikethrough(true, color: Color.triggerLightGray.opacity(0.5))

                Text(reminder.formattedCompletedAgo)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.triggerLightGray.opacity(0.6))
            }

            Spacer()

            if reminder.xpEarned > 0 {
                Text("+\(reminder.xpEarned) XP")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.triggerOrange.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.triggerCard.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
