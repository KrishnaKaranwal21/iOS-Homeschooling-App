import SwiftUI
import AVFoundation

/// Owns the audio session, the recorder and the player. Starting or stopping audio blocks until the hardware responds,
/// so doing it on the main thread freezes the UI ("AVAudioSession Hang Risk"). An actor runs every call off the main
/// thread, one at a time. The main-actor `VoiceRecorder` and `VoicePlayer` below only hold what the screen shows.
actor AudioEngine {
    static let shared = AudioEngine()

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var playerDelegate: PlayerDelegate?

    // MARK: Recording

    /// Starts recording to `url`. Returns false when recording could not begin.
    func startRecording(to url: URL) throws -> Bool {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        guard recorder.record() else { return false }
        self.recorder = recorder
        return true
    }

    func recordingTime() -> TimeInterval { recorder?.currentTime ?? 0 }

    /// Stops recording, releases the audio session and returns how long the recording ran.
    func stopRecording() -> TimeInterval {
        let duration = recorder?.currentTime ?? 0
        recorder?.stop()
        recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return duration
    }

    // MARK: Playback

    /// Starts playing `data`. `onFinish` is called when it reaches the end. Returns false when it could not play.
    func startPlayback(_ data: Data, onFinish: @escaping @Sendable () -> Void) -> Bool {
        stopPlayback()
        guard let player = try? AVAudioPlayer(data: data) else { return false }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback)
        try? session.setActive(true)
        let delegate = PlayerDelegate(onFinish: onFinish)
        player.delegate = delegate
        guard player.play() else { return false }
        self.player = player
        playerDelegate = delegate
        return true
    }

    /// How far playback has got, from 0 to 1.
    func playbackProgress() -> Double {
        guard let player, player.duration > 0 else { return 0 }
        return player.currentTime / player.duration
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        playerDelegate = nil
    }
}

/// Tells the engine's owner when a voice message finishes playing. It is `nonisolated` because the project isolates
/// types to the main actor by default, and the audio engine creates this on its own actor.
private nonisolated final class PlayerDelegate: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    let onFinish: @Sendable () -> Void
    init(onFinish: @escaping @Sendable () -> Void) { self.onFinish = onFinish }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { onFinish() }
}

/// Records one voice message at a time. The app needs a "Privacy - Microphone Usage Description" in its Info settings.
@MainActor
@Observable
final class VoiceRecorder {
    private(set) var isRecording = false
    private(set) var elapsed: TimeInterval = 0

    private var fileURL: URL?
    private var timerTask: Task<Void, Never>?

    /// Asks for permission if needed, then starts. Returns false when the microphone isn't allowed.
    func start() async -> Bool {
        guard await AVAudioApplication.requestRecordPermission() else { return false }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("voice-\(UUID().uuidString).m4a")
        guard (try? await AudioEngine.shared.startRecording(to: url)) == true else { return false }

        fileURL = url
        elapsed = 0
        isRecording = true
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard let self, self.isRecording else { return }
                self.elapsed = await AudioEngine.shared.recordingTime()
            }
        }
        return true
    }

    /// Stops and returns the recording, or nil when it was too short to be useful.
    func stop() async -> (data: Data, duration: TimeInterval)? {
        let url = fileURL
        let duration = await finish()
        defer { if let url { try? FileManager.default.removeItem(at: url) } }
        guard duration >= 0.5, let url, let data = try? Data(contentsOf: url) else { return nil }
        return (data, duration)
    }

    func cancel() {
        let url = fileURL
        Task {
            await finish()
            if let url { try? FileManager.default.removeItem(at: url) }
        }
    }

    @discardableResult
    private func finish() async -> TimeInterval {
        timerTask?.cancel()
        isRecording = false
        elapsed = 0
        fileURL = nil
        return await AudioEngine.shared.stopRecording()
    }
}

/// Plays one voice message at a time.
@MainActor
@Observable
final class VoicePlayer {
    private(set) var playingID: ChatMessage.ID?
    private(set) var progress: Double = 0

    private var timerTask: Task<Void, Never>?

    func toggle(_ message: ChatMessage) {
        if playingID == message.id { stop(); return }
        stop()
        guard let data = message.audioData else { return }
        let id = message.id
        playingID = id
        timerTask = Task { [weak self] in
            // The engine starts playback off the main thread; the bubble shows as playing straight away.
            let started = await AudioEngine.shared.startPlayback(data) {
                Task { @MainActor in
                    if self?.playingID == id { self?.stop() }
                }
            }
            guard started, !Task.isCancelled else {
                if !started { self?.stop() }
                return
            }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, self.playingID == id else { return }
                self.progress = await AudioEngine.shared.playbackProgress()
            }
        }
    }

    func stop() {
        timerTask?.cancel()
        timerTask = nil
        playingID = nil
        progress = 0
        Task { await AudioEngine.shared.stopPlayback() }
    }
}
