import SwiftUI

struct ContentView: View {
    @Environment(AppStore.self) private var store
    @State private var selectedTab: Int = {
        if CommandLine.arguments.contains("--tab-reminders") { return 1 }
        if CommandLine.arguments.contains("--tab-stats") { return 2 }
        return 0
    }()

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                CaptureView()
                    .tag(0)

                RemindersListView()
                    .tag(1)

                StatsView()
                    .tag(2)
            }
            .tabViewStyle(.automatic)
            .background(Color.triggerBG)

            // Custom tab bar
            CustomTabBar(selectedTab: $selectedTab, pendingCount: store.pendingReminders.count)
        }
        .ignoresSafeArea(edges: .bottom)
        .background(Color.triggerBG)
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let pendingCount: Int

    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(icon: "bolt.fill",  label: "Trigger", index: 0, selected: $selectedTab)
            TabBarButton(icon: "list.bullet", label: "Meine",  index: 1, selected: $selectedTab, badge: pendingCount)
            TabBarButton(icon: "chart.bar.fill", label: "Stats", index: 2, selected: $selectedTab)
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Color.triggerCard
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.triggerCardBorder),
                    alignment: .top
                )
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let index: Int
    @Binding var selected: Int
    var badge: Int = 0

    var isSelected: Bool { selected == index }

    var body: some View {
        Button {
            HapticManager.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selected = index
            }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                        .foregroundStyle(isSelected ? Color.triggerOrange : Color.triggerLightGray)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: isSelected)

                    if badge > 0 {
                        Text("\(min(badge, 99))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(Color.triggerOrange)
                            .clipShape(Circle())
                            .offset(x: 8, y: -8)
                    }
                }
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.triggerOrange : Color.triggerLightGray)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
