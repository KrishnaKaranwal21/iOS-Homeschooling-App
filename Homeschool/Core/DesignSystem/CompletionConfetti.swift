import SwiftUI

/// A short, noninteractive celebration for each completed learning activity.
struct CompletionConfetti: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bursts: [Burst] = []
    let trigger: Int

    private struct Burst {
        let id: Int
        let started: Date
    }

    private let duration = 2.2
    private let colors = [Theme.lavender, Theme.accent, Theme.coral,
                          Color(hex: 0x81BFA6), Color(hex: 0xE5BD62)]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: bursts.isEmpty || reduceMotion)) { timeline in
            Canvas { context, size in
                for burst in bursts {
                    let elapsed = timeline.date.timeIntervalSince(burst.started)
                    guard elapsed >= 0, elapsed < duration else { continue }
                    let fade = min(1, elapsed * 12) * min(1, (duration - elapsed) / 0.6)
                    for index in 0..<64 {
                        let seed = Double(index + burst.id * 67)
                        let spread = sin(seed * 2.399)
                        let variation = (cos(seed * 1.73) + 1) / 2
                        let age = elapsed - (sin(seed * 0.91) + 1) * 0.14
                        guard age >= 0 else { continue }
                        let fallSpeed = (sin(seed * 1.37) + 1) / 2
                        let gravity = (sin(seed * 0.73) + 1) / 2
                        let x = size.width * (0.5 + spread * 0.22)
                            + spread * size.width * 0.20 * age
                            + sin(age * 5 + seed) * 12
                        let y = -24 - variation * 45
                            + (50 + fallSpeed * 120) * age
                            + size.height * (0.10 + gravity * 0.16) * age * age
                        var particle = context
                        particle.opacity = fade * (0.7 + variation * 0.3)
                        particle.translateBy(x: x, y: y)
                        particle.rotate(by: .degrees(seed * 31 + age * (spread * 220)))
                        let width = (4 + variation * 3) * max(0.25, abs(cos(age * 6 + seed)))
                        let rect = CGRect(x: -width / 2, y: -4, width: width, height: index.isMultiple(of: 3) ? width : 8)
                        let shape = Path(roundedRect: rect, cornerRadius: index.isMultiple(of: 3) ? width / 2 : 1)
                        particle.fill(shape, with: .color(colors[index % colors.count]))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: trigger) {
            guard trigger > 0, !reduceMotion else { return }
            let now = Date()
            bursts.removeAll { now.timeIntervalSince($0.started) >= duration }
            bursts.append(Burst(id: trigger, started: now))
            // Bound the drawing work when several tasks are completed quickly.
            bursts = Array(bursts.suffix(4))
            do { try await Task.sleep(for: .seconds(duration)) }
            catch { return }
            bursts.removeAll { $0.id <= trigger }
        }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced { bursts.removeAll() }
        }
    }
}
