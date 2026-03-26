import SwiftUI

struct CaptureView: View {
    @Environment(AppStore.self) private var store
    @State private var speechService = SpeechService()
    @State private var reminderText: String = ""
    @State private var selectedHours: Double = 4.0
    @State private var showInput: Bool = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var showSuccess: Bool = false
    @State private var xpFlyIn: Bool = false
    @State private var captureTime: Date?

    private let timeOptions: [(label: String, hours: Double)] = [
        ("30m", 0.5), ("1h", 1.0), ("2h", 2.0), ("4h", 4.0), ("8h", 8.0), ("24h", 24.0)
    ]

    var body: some View {
        ZStack {
            Color.triggerBG.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerBar

                Spacer()

                if !showInput {
                    // Idle state: big pulsing button
                    idleState
                } else {
                    // Active capture state
                    captureState
                }

                Spacer()
            }

            // Success overlay
            if showSuccess {
                successOverlay
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showInput)
        .onTapGesture {
            if showInput && reminderText.isEmpty && !speechService.isRecording {
                withAnimation { showInput = false }
            }
        }
        .onChange(of: speechService.transcribedText) { _, newText in
            if !newText.isEmpty { reminderText = newText }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TRIGGER")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(Color.triggerOrange)
                Text("Gedanken raus. Sofort.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.triggerLightGray)
            }
            Spacer()
            // Quick stats
            HStack(spacing: 12) {
                statPill(icon: "flame.fill", value: "\(store.userStats.currentStreak)", color: .orange)
                statPill(icon: "bolt.fill", value: "Lv.\(store.userStats.level)", color: Color.triggerOrange)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func statPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.triggerDarkWhite)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.triggerCard)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.triggerCardBorder, lineWidth: 0.5))
    }

    // MARK: - Idle State

    private var idleState: some View {
        VStack(spacing: 32) {
            Text("Was geht dir gerade\ndurch den Kopf?")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color.triggerDarkWhite)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // Big pulsing capture button
            Button {
                HapticManager.heavy()
                captureTime = Date()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    showInput = true
                }
            } label: {
                ZStack {
                    // Pulse rings
                    Circle()
                        .fill(Color.triggerOrange.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseScale)
                    Circle()
                        .fill(Color.triggerOrange.opacity(0.08))
                        .frame(width: 170, height: 170)
                        .scaleEffect(pulseScale)

                    // Main circle
                    Circle()
                        .fill(LinearGradient.triggerOrangeGradient)
                        .frame(width: 110, height: 110)
                        .shadow(color: Color.triggerOrange.opacity(0.5), radius: 20, x: 0, y: 8)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .onAppear { startPulse() }

            Text("Antippen zum Starten")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.triggerLightGray)
        }
    }

    // MARK: - Capture State

    private var captureState: some View {
        VStack(spacing: 20) {
            // Text input
            ZStack(alignment: .topLeading) {
                if reminderText.isEmpty && !speechService.isRecording {
                    Text("Erinnerung eingeben…")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.triggerLightGray)
                        .padding(.horizontal, 4)
                        .padding(.top, 2)
                }

                TextEditor(text: $reminderText)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.triggerDarkWhite)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 80, maxHeight: 140)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.sentences)
            }
            .padding(16)
            .background(Color.triggerCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        speechService.isRecording ? Color.triggerOrange : Color.triggerCardBorder,
                        lineWidth: speechService.isRecording ? 1.5 : 0.5
                    )
            )
            .padding(.horizontal, 24)

            // Voice waveform (shown while recording)
            if speechService.isRecording {
                VoiceWaveformView(level: speechService.audioLevel)
                    .transition(.opacity.combined(with: .scale))
            }

            // Time picker
            VStack(spacing: 8) {
                Text("Erinnerung in")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.triggerLightGray)

                HStack(spacing: 8) {
                    ForEach(timeOptions, id: \.hours) { option in
                        TimeChip(
                            label: option.label,
                            isSelected: selectedHours == option.hours
                        ) {
                            HapticManager.light()
                            withAnimation(.spring(response: 0.25)) {
                                selectedHours = option.hours
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            // Action buttons
            HStack(spacing: 12) {
                // Voice button
                Button {
                    handleVoiceToggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(speechService.isRecording ? Color.triggerOrange : Color.triggerCard)
                            .frame(width: 56, height: 56)
                            .overlay(Circle().strokeBorder(Color.triggerCardBorder, lineWidth: 0.5))

                        Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(speechService.isRecording ? .white : Color.triggerOrange)
                    }
                }
                .buttonStyle(.plain)

                // FIRE button
                Button {
                    fireReminder()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("FIRE")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Group {
                            if reminderText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Color.triggerMediumGray
                            } else {
                                LinearGradient.triggerOrangeGradient
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(
                        color: reminderText.isEmpty ? .clear : Color.triggerOrange.opacity(0.4),
                        radius: 12, x: 0, y: 4
                    )
                }
                .buttonStyle(.plain)
                .disabled(reminderText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                // Cancel button
                Button {
                    HapticManager.light()
                    speechService.stopRecording()
                    withAnimation(.spring(response: 0.35)) {
                        showInput = false
                        reminderText = ""
                    }
                } label: {
                    Circle()
                        .fill(Color.triggerCard)
                        .frame(width: 56, height: 56)
                        .overlay(Circle().strokeBorder(Color.triggerCardBorder, lineWidth: 0.5))
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.triggerLightGray)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture { withAnimation { showSuccess = false } }

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.triggerOrange.opacity(0.2))
                        .frame(width: 100, height: 100)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(Color.triggerOrange)
                }
                .scaleEffect(showSuccess ? 1.0 : 0.1)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showSuccess)

                Text("Trigger gesetzt!")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(Color.triggerDarkWhite)

                Text("Du wirst in \(formattedSelectedTime) erinnert.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.triggerLightGray)
                    .multilineTextAlignment(.center)

                // XP gained
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(Color.triggerOrange)
                        .font(.system(size: 12, weight: .bold))
                    Text("+10 XP")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Color.triggerOrange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.triggerOrange.opacity(0.15))
                .clipShape(Capsule())
            }
            .padding(32)
            .background(Color.triggerCard)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 48)
            .shadow(color: .black.opacity(0.5), radius: 30)
        }
        .transition(.opacity)
    }

    // MARK: - Helpers

    private var formattedSelectedTime: String {
        if selectedHours < 1 { return "30 Minuten" }
        if selectedHours == 1 { return "1 Stunde" }
        if selectedHours < 24 { return "\(Int(selectedHours)) Stunden" }
        return "24 Stunden"
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
    }

    private func handleVoiceToggle() {
        if speechService.isRecording {
            HapticManager.light()
            speechService.stopRecording()
        } else {
            HapticManager.heavy()
            Task { await speechService.startRecording() }
        }
    }

    private func fireReminder() {
        let text = reminderText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let remindAt = Date().addingTimeInterval(selectedHours * 3600)
        let usedVoice = speechService.usedVoiceInSession

        // Quick draw achievement: set reminder in < 5 seconds
        var quickDraw = false
        if let start = captureTime, Date().timeIntervalSince(start) < 5 {
            quickDraw = true
        }

        HapticManager.success()
        speechService.stopRecording()

        store.addReminder(text: text, remindAt: remindAt, usedVoice: usedVoice)

        if quickDraw, let idx = store.userStats.achievements.firstIndex(where: { $0.key == "quick_draw" }),
           !store.userStats.achievements[idx].isUnlocked {
            store.userStats.achievements[idx].unlockedAt = Date()
            store.userStats.totalXP += 50
            store.saveData()
        }

        withAnimation(.spring(response: 0.35)) {
            showInput = false
            reminderText = ""
            showSuccess = true
        }

        // Auto-dismiss success overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { showSuccess = false }
        }
    }
}

// MARK: - Time Chip

struct TimeChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? .white : Color.triggerLightGray)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(isSelected ? Color.triggerOrange : Color.triggerCard)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(
                    isSelected ? Color.clear : Color.triggerCardBorder, lineWidth: 0.5
                ))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: isSelected)
    }
}

// MARK: - Voice Waveform View

struct VoiceWaveformView: View {
    let level: Float
    @State private var bars: [CGFloat] = Array(repeating: 0.2, count: 20)
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<bars.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.triggerOrange)
                    .frame(width: 3, height: max(4, bars[i] * 40))
                    .animation(.easeOut(duration: 0.1), value: bars[i])
            }
        }
        .frame(height: 50)
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
                for i in 0..<bars.count {
                    let rand = CGFloat.random(in: 0.1...1.0)
                    bars[i] = CGFloat(level) * rand + 0.15
                }
            }
        }
        .onDisappear { timer?.invalidate() }
    }
}

// MARK: - SpeechService extension for session tracking

extension SpeechService {
    var usedVoiceInSession: Bool { !transcribedText.isEmpty }
}
