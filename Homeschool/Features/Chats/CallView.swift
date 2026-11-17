import SwiftUI

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
                                .scaledFont(22, weight: .semibold)
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
                    .scaledFont(20, weight: .semibold)
                    .foregroundStyle(Theme.ink)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(on ? Theme.lavender : Theme.surface))
                Text(title).caption()
            }
        }
        .buttonStyle(.plain)
    }
}
