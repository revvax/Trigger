import SwiftUI
import Speech
import AVFoundation

@Observable
@MainActor
class SpeechService {
    var isRecording: Bool = false
    var transcribedText: String = ""
    var audioLevel: Float = 0.0
    var permissionDenied: Bool = false

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
        if speechRecognizer == nil {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        }
    }

    func requestPermissions() async -> Bool {
        #if os(iOS)
        let micStatus = await AVAudioApplication.requestRecordPermission()
        guard micStatus else { permissionDenied = true; return false }
        #endif

        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    let granted = status == .authorized
                    if !granted { self.permissionDenied = true }
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func startRecording() async {
        guard !isRecording else { return }

        let granted = await requestPermissions()
        guard granted, let recognizer = speechRecognizer, recognizer.isAvailable else { return }

        let engine = AVAudioEngine()
        audioEngine = engine

        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
            return
        }
        #endif

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false
        recognitionRequest = request

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            request.append(buffer)

            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<frameLength { sum += abs(channelData[i]) }
            let level = sum / Float(max(frameLength, 1))
            DispatchQueue.main.async {
                self?.audioLevel = min(level * 50, 1.0)
            }
        }

        do {
            try engine.start()
        } catch {
            print("Audio engine error: \(error)")
            return
        }

        isRecording = true
        transcribedText = ""

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self?.stopRecording()
                }
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil

        isRecording = false
        audioLevel = 0.0

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
    }
}
