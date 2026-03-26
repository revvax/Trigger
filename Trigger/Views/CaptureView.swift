import SwiftUI

struct CaptureView: View {
    @Environment(AppStore.self) private var store
    @State private var speechService = SpeechService()
    @State private var reminderText: String = ""
    @State private var selectedHours: Double = 4.0
    @State private var showInput: Bool = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var showSuccess: Bool = false
    @State private var captureTime: Date?

    // Custom timer
    @State private var showCustomPicker: Bool = false
    @State private var customPickerHours: Int = 1
    @State private var customPickerMinutes: Int = 0
    private let customSentinel: Double = -1.0

    private let timeOptions: [(label: String, hours: Double)] = [
        ("30m", 0.5), ("1h", 1.0), ("2h", 2.0), ("4h", 4.0), ("8h", 8.0), ("24h", 24.0)
    ]

    // Effective duration accounting for custom picker
    private var effectiveHours: Double {
        guard selectedHours == customSentinel else { return selectedHours }
        let total = Double(customPickerHours) + Double(customPickerMinutes) / 60.0
        return max(total, 1.0 / 12.0) // minimum 5 minutes
    }

    private var customTimeLabel: String {
        if customPickerHours == 0 { return "\(customPickerMinutes)m" }
        if customPickerMinutes == 0 { return "\(customPickerHours)h" }
        return "\(customPickerHours)h\(customPickerMinutes)m"
    }

    var body: some View {
        ZStack {
            Color.triggerBG.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                Spacer()
                if !showInput {
                    idleState
                } else {
                    captureState
                }
                Spacer()
            }

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

            Button {
                HapticManager.heavy()
                captureTime = Date()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    showInput = true
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.triggerOrange.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseScale)
                    Circle()
                        .fill(Color.triggerOrange.opacity(0.08))
                        .frame(width: 170, height: 170)
                        .scaleEffect(pulseScale)
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

            if speechService.isRecording {
                VoiceWaveformView(level: speechService.audioLevel)
                    .transition(.opacity.combined(with: .scale))
            }

            // Time picker row
            VStack(spacing: 8) {
                HStack {
                    Text("Erinnerung in")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.triggerLightGray)
                    Spacer()
                    // Show resolved time when custom is active
                    if selectedHours == customSentinel {
                        Text(formattedSelectedTime)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.triggerOrange)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 24)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(timeOptions, id: \.hours) { option in
                            TimeChip(
                                label: option.label,
                                isSelected: selectedHours == option.hours
                            ) {
                                HapticManager.light()
                                withAnimation(.spring(response: 0.25)) {
                                    selectedHours = option.hours
                                    showCustomPicker = false
                                }
                            }
                        }
                        // Custom chip
                        TimeChip(
                            label: selectedHours == customSentinel ? customTimeLabel : "⏱",
                            isSelected: selectedHours == customSentinel,
                            isCustom: true
                        ) {
                            HapticManager.light()
                            withAnimation(.spring(response: 0.3)) {
                                selectedHours = customSentinel
                                showCustomPicker = true
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }

            // Inline custom time picker
            if showCustomPicker {
                customTimePicker
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Action buttons
            HStack(spacing: 12) {
                Button { handleVoiceToggle() } label: {
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

                Button { fireReminder() } label: {
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

                Button {
                    HapticManager.light()
                    speechService.stopRecording()
                    withAnimation(.spring(response: 0.35)) {
                        showInput = false
                        reminderText = ""
                        showCustomPicker = false
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

    // MARK: - Custom Time Picker

    private var customTimePicker: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Eigene Zeit")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.triggerLightGray)
                Spacer()
                Text(formattedSelectedTime)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.triggerOrange)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            HStack(spacing: 0) {
                // Hours wheel (0–47)
                VStack(spacing: 4) {
                    Text("Stunden")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.triggerLightGray.opacity(0.7))
                    Picker("", selection: $customPickerHours) {
                        ForEach(0...47, id: \.self) { h in
                            Text("\(h)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.triggerDarkWhite)
                                .tag(h)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                    .clipped()
                }
                .frame(maxWidth: .infinity)

                // Separator
                Text(":")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.triggerOrange)
                    .padding(.bottom, 4)

                // Minutes wheel (0, 5, 10, …, 55)
                VStack(spacing: 4) {
                    Text("Minuten")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.triggerLightGray.opacity(0.7))
                    Picker("", selection: $customPickerMinutes) {
                        ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { m in
                            Text(String(format: "%02d", m))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.triggerDarkWhite)
                                .tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                    .clipped()
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color.triggerCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.triggerOrange.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 24)
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
        let h = effectiveHours
        if h < 1 {
            let mins = Int(h * 60)
            return "\(mins) Minuten"
        }
        let hours = Int(h)
        let mins = Int((h - Double(hours)) * 60)
        if mins == 0 {
            return hours == 1 ? "1 Stunde" : "\(hours) Stunden"
        }
        return "\(hours)h \(mins)m"
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

        let remindAt = Date().addingTimeInterval(effectiveHours * 3600)
        let usedVoice = speechService.usedVoiceInSession

        let quickDraw = captureTime.map { Date().timeIntervalSince($0) < 5 } ?? false

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
            showCustomPicker = false
            showSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { showSuccess = false }
        }
    }
}

// MARK: - Time Chip

struct TimeChip: View {
    let label: String
    let isSelected: Bool
    var isCustom: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: isCustom && !isSelected ? 3 : 0) {
                if isCustom && !isSelected {
                    Image(systemName: "timer")
                        .font(.system(size: 11, weight: .bold))
                }
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
            }
            .foregroundStyle(isSelected ? .white : (isCustom ? Color.triggerOrange : Color.triggerLightGray))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isSelected ? Color.triggerOrange : Color.triggerCard)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(
                isSelected ? Color.clear : (isCustom ? Color.triggerOrange.opacity(0.5) : Color.triggerCardBorder),
                lineWidth: 0.5
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
                    bars[i] = CGFloat(level) * CGFloat.random(in: 0.1...1.0) + 0.15
                }
            }
        }
        .onDisappear { timer?.invalidate() }
    }
}

// MARK: - SpeechService extension

extension SpeechService {
    var usedVoiceInSession: Bool { !transcribedText.isEmpty }
}
