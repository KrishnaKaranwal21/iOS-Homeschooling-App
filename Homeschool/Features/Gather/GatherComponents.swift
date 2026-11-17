import SwiftUI

// MARK: - Event extensions

extension Event {
    /// Colour used when an event has no photo yet.
    var tint: Color {
        switch normalizedCategory {
        case "Nature":  return Color(hex: 0x7FA777)
        case "Art":     return Color(hex: 0xE8A07F)
        case "Sports":  return Color(hex: 0x8FA8E8)
        case "Music":   return Color(hex: 0xE59AA0)
        default:        return Color(hex: 0x9C8CF0)
        }
    }
}

// MARK: - EventCover

/// Photo picked by the host, then an image from the asset catalog, then a soft colour with the event symbol.
/// The caller sets the frame.
struct EventCover: View {
    let event: Event

    var body: some View {
        Color.clear
            .overlay { content }
            .clipped()
    }

    @ViewBuilder private var content: some View {
        if let cover = event.coverImage {
            cover.image.resizable().scaledToFill()
        } else if let name = event.coverName, let image = UIImage(named: name) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            GatherEventPoster(event: event)
        }
    }
}

// MARK: - GatherPageDots

struct GatherPageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Theme.ink : Theme.dotInactive)
                    .frame(width: index == current ? 26 : 7, height: 7)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.snappy, value: current)
        .accessibilityHidden(true)
    }
}

// MARK: - GatherInfoRow

struct GatherInfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .scaledFont(14, maxScale: 1.3)
                .frame(width: 18)
            Text(text)
                .scaledFont(14, maxScale: 1.3)
                .lineLimit(1)
        }
        .foregroundStyle(Theme.gatherText)
    }
}

// MARK: - GatherSegmented

/// Native segmented control. On iOS 26 and newer it renders as Liquid Glass with a white sliding
/// highlight, matching the "Tuesday / Whole week" switch on the Progress page.
struct GatherSegmented<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let title: (Value) -> String

    var body: some View {
        Picker("Selection", selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(title(option)).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .tint(.white)
        .frame(height: 48)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

// MARK: - GatherDateField

/// Tap to open a calendar. Choosing a day saves it and closes the calendar.
struct GatherDateField: View {
    @Binding var date: Date
    @State private var isPresented = false

    var body: some View {
        Button { isPresented = true } label: {
            HStack {
                Text(date.formatted(.dateTime.weekday(.wide)))
                Spacer()
                Text(date.formatted(.dateTime.month(.abbreviated).day().year()))
            }
            .scaledFont(16, maxScale: 1.3)
            .foregroundStyle(Theme.ink)
            .gatherField()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPresented) {
            DatePicker("Date", selection: $date, in: Date.now..., displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(12)
                .frame(width: 330)
                .presentationCompactAdaptation(.popover)
        }
        // Choosing a day saves it and closes the calendar.
        .onChange(of: date) { isPresented = false }
    }
}

// MARK: - GatherTimeField

struct GatherTimeField: View {
    @Binding var date: Date
    @State private var isPresented = false

    var body: some View {
        Button { isPresented = true } label: {
            Text(date.formatted(date: .omitted, time: .shortened))
                .scaledFont(16, maxScale: 1.3)
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .gatherField()
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPresented) {
            DatePicker("Time", selection: $date, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(width: 240)
                .padding(8)
                .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - GatherWaveShape

/// Cover photo outline: rounded top corners and a gentle wave along the bottom edge.
struct GatherWaveShape: Shape {
    var cornerRadius: CGFloat = 40
    var lift: CGFloat = 34

    func path(in rect: CGRect) -> Path {
        let r = cornerRadius
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.minY),
                          control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r),
                          control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - r, y: rect.maxY),
                          control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addCurve(to: CGPoint(x: rect.minX + r, y: rect.maxY - lift),
                      control1: CGPoint(x: rect.maxX * 0.62, y: rect.maxY + 8),
                      control2: CGPoint(x: rect.maxX * 0.38, y: rect.maxY - lift - 30))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - lift - r),
                          control: CGPoint(x: rect.minX, y: rect.maxY - lift))
        path.closeSubpath()
        return path
    }
}

// MARK: - DashedLine

struct DashedLine: Shape {
    let vertical: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if vertical {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
        return path
    }
}

// MARK: - EventAttendingBadge

/// "Attending" / "Hosting" pill shown on an event cover.
/// A white pill with dark text stays readable over any event cover.
struct EventAttendingBadge: View {
    var title = "Going"
    var symbol = "checkmark.circle.fill"
    var tint = Color(hex: 0x3F9E7E)

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
            Text(title)
                .foregroundStyle(Color(hex: 0x2B2840))
                .lineLimit(1)
        }
        .scaledFont(13, weight: .semibold, maxScale: 1.3)
        .fixedSize()
        .padding(.horizontal, 11).padding(.vertical, 8)
        .background(Capsule().fill(Color.white))
        .overlay(Capsule().stroke(Color(hex: 0xDDD7F5), lineWidth: 1))
        .shadow(color: .black.opacity(0.15), radius: 4, y: 1)
        .environment(\.colorScheme, .light)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - EventModeBadge

struct EventModeBadge: View {
    let mode: Event.Mode

    var body: some View {
        Label(mode.rawValue, systemImage: mode == .online ? "video.fill" : "mappin")
            .scaledFont(11, weight: .semibold, maxScale: 1.25)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Theme.field, in: Capsule())
            .fixedSize()
    }
}

// MARK: - GatherFeedCategory extensions

/// Soft category colours remain legible against both Gather backgrounds.
extension GatherFeedCategory {
    var iconColor: Color {
        switch self {
        case .explore: Color(hex: 0x8262CF)
        case .yours: Color(hex: 0xAD7390)
        case .art: Color(hex: 0xB66D88)
        case .nature: Color(hex: 0x51856D)
        case .music: Color(hex: 0xB57A49)
        case .sports: Color(hex: 0x577FA7)
        case .study: Color(hex: 0x7971AC)
        }
    }
}
