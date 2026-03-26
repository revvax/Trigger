import SwiftUI

struct RemindersListView: View {
    @Environment(AppStore.self) private var store
    @State private var showCompleted: Bool = false

    var body: some View {
        ZStack {
            Color.triggerBG.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header
                    listHeader
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    if store.pendingReminders.isEmpty {
                        emptyState
                            .padding(.top, 60)
                    } else {
                        // Pending reminders
                        VStack(spacing: 8) {
                            ForEach(store.pendingReminders) { reminder in
                                ReminderCard(
                                    reminder: reminder,
                                    onComplete: { store.completeReminder(reminder) },
                                    onDelete: { store.deleteReminder(reminder) },
                                    onSnooze: { hours in store.snoozeReminder(reminder, hours: hours) }
                                )
                                .transition(.asymmetric(
                                    insertion: .slide.combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .animation(.spring(response: 0.4), value: store.pendingReminders.count)
                    }

                    // Completed section
                    if !store.completedReminders.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                HapticManager.light()
                                withAnimation(.spring(response: 0.3)) {
                                    showCompleted.toggle()
                                }
                            } label: {
                                HStack {
                                    Text("Erledigt (\(store.completedReminders.count))")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.triggerLightGray)
                                    Spacer()
                                    Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.triggerLightGray)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)

                            if showCompleted {
                                VStack(spacing: 6) {
                                    ForEach(store.completedReminders) { reminder in
                                        CompletedReminderCard(reminder: reminder)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(.top, 16)
                    }

                    // Bottom padding for tab bar
                    Spacer().frame(height: 100)
                }
            }
        }
    }

    // MARK: - Header

    private var listHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Meine Trigger")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(Color.triggerDarkWhite)
                if store.pendingReminders.isEmpty {
                    Text("Alles erledigt 🎉")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.triggerLightGray)
                } else {
                    Text("\(store.pendingReminders.count) offen")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.triggerOrange)
                }
            }
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.triggerOrange.opacity(0.08))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.triggerOrange.opacity(0.4))
            }

            VStack(spacing: 8) {
                Text("Alles im Griff!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.triggerDarkWhite)

                Text("Stell einen neuen Trigger\nüber den ⚡-Tab ein.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.triggerLightGray)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
