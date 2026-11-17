import SwiftUI

/// The play/pause control and duration for a voice note inside a chat bubble.
struct VoiceBubble: View {
    let message: ChatMessage
    let player: VoicePlayer

    private var isPlaying: Bool { player.playingID == message.id }

    var body: some View {
        HStack(spacing: 12) {
            Button { player.toggle(message) } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .scaledFont(16, weight: .bold)
                    .foregroundStyle(Theme.ink)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Theme.surface.opacity(0.85)))
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
