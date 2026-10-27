import SwiftUI
import AVFoundation

// MARK: - Recording

/// Records one voice message at a time. The app needs a "Privacy - Microphone Usage Description" in its Info settings.
@MainActor
@Observable
final class VoiceRecorder {
    private(set) var isRecording = false
    private(set) var elapsed: TimeInterval = 0

    private var recorder: AVAudioRecorder?
    private var fileURL: URL?
    private var timerTask: Task<Void, Never>?

    /// Asks for permission if needed, then starts. Returns false when the microphone isn't allowed.
    func start() async -> Bool {
        guard await AVAudioApplication.requestRecordPermission() else { return false }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("voice-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            guard recorder.record() else { return false }

            self.recorder = recorder
            fileURL = url
            elapsed = 0
            isRecording = true
            timerTask = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(200))
                    guard let self, let recorder = self.recorder else { return }
                    self.elapsed = recorder.currentTime
                }
            }
            return true
        } catch {
            return false
        }
    }

    /// Stops and returns the recording, or nil when it was too short to be useful.
    func stop() -> (data: Data, duration: TimeInterval)? {
        let duration = recorder?.currentTime ?? 0
        let url = fileURL
        finish()
        defer { if let url { try? FileManager.default.removeItem(at: url) } }
        guard duration >= 0.5, let url, let data = try? Data(contentsOf: url) else { return nil }
        return (data, duration)
    }

    func cancel() {
        let url = fileURL
        finish()
        if let url { try? FileManager.default.removeItem(at: url) }
    }

    private func finish() {
        recorder?.stop()
        recorder = nil
        fileURL = nil
        timerTask?.cancel()
        isRecording = false
        elapsed = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - Playback

/// Plays one voice message at a time.
@MainActor
@Observable
final class VoicePlayer: NSObject, AVAudioPlayerDelegate {
    private(set) var playingID: ChatMessage.ID?
    private(set) var progress: Double = 0

    private var player: AVAudioPlayer?
    private var timerTask: Task<Void, Never>?

    func toggle(_ message: ChatMessage) {
        if playingID == message.id { stop(); return }
        stop()
        guard let data = message.audioData, let player = try? AVAudioPlayer(data: data) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        player.delegate = self
        player.play()
        self.player = player
        playingID = message.id
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, let player = self.player else { return }
                self.progress = player.duration > 0 ? player.currentTime / player.duration : 0
            }
        }
    }

    func stop() {
        player?.stop()
        player = nil
        timerTask?.cancel()
        playingID = nil
        progress = 0
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.stop() }
    }
}

// MARK: - Bubble content

struct VoiceBubble: View {
    let message: ChatMessage
    let player: VoicePlayer

    private var isPlaying: Bool { player.playingID == message.id }

    var body: some View {
        HStack(spacing: 12) {
            Button { player.toggle(message) } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(0.85)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? "Pause voice message" : "Play voice message")

            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: isPlaying ? player.progress : 0)
                    .tint(Theme.ink)
                    .frame(width: 120)
                Text(ChatFormat.duration(message.audioDuration))
                    .scaledFont(12, maxScale: 1.2)
                    .foregroundStyle(Theme.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Calls

enum CallMode: String, Identifiable {
    case voice, video
    var id: String { rawValue }
}

/// The call screen. Calls aren't connected to a service yet, so it rings and then says so.
struct CallView: View {
    let thread: ChatThread?
    let mode: CallMode

    @Environment(\.dismiss) private var dismiss
    @State private var status = "Calling…"
    @State private var isMuted = false
    @State private var speakerOn = false

    var body: some View {
        ZStack {
            Color(hex: 0xE6E1FF).ignoresSafeArea()

            VStack(spacing: 12) {
                Spacer()
                if let thread {
                    ChatAvatar(thread: thread, size: 132)
                    Text(thread.title)
                        .detailTitle()
                }
                Text(mode == .video ? "Video call" : "Voice call")
                    .rowDetail()
                Text(status)
                    .scaledFont(17, weight: .medium, maxScale: 1.3)
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 6)
                Spacer()

                HStack(spacing: 24) {
                    control(isMuted ? "mic.slash.fill" : "mic.fill", title: "Mute", on: isMuted) { isMuted.toggle() }
                    control("speaker.wave.2.fill", title: "Speaker", on: speakerOn) { speakerOn.toggle() }
                    Button { dismiss() } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "phone.down.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .frame(width: 64, height: 64)
                                .background(Circle().fill(Color.red))
                            Text("End").caption()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("End call")
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .task {
            try? await Task.sleep(for: .seconds(4))
            status = "Calls aren’t available yet"
        }
    }

    private func control(_ symbol: String, title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(on ? Theme.lavender : Color.white))
                Text(title).caption()
            }
        }
        .buttonStyle(.plain)
    }
}
