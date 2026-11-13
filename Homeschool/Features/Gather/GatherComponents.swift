import SwiftUI

// MARK: - Cover image

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

// MARK: - Small pieces

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

/// Capsule switch with a sliding highlight, e.g. Gathering / Workshop.
struct GatherSegmented<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let title: (Value) -> String
    @Namespace private var highlight

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.snappy) { selection = option }
                } label: {
                    Text(title(option))
                        .scaledFont(15, weight: selection == option ? .semibold : .regular, maxScale: 1.3)
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background {
                            if selection == option {
                                Capsule()
                                    .fill(Theme.lilac)
                                    .matchedGeometryEffect(id: "highlight", in: highlight)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == option ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Capsule().fill(Theme.surface))
        .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
    }
}

// MARK: - Date and time fields

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

// MARK: - Shapes

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

// MARK: - "Your next gathering" ticket

struct TicketCard: View {
    let event: Event
    let onViewConfirmation: () -> Void

    private let tileColumn: CGFloat = 114
    private let dashColor = Theme.ink.opacity(0.22)
    private let warmText = Color.adaptive(0x9C4A4B, 0xF0ADAA)
    fileprivate static let topHeight: CGFloat = 128
    fileprivate static let cardHeight: CGFloat = 176

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                dateTile
                    .frame(width: tileColumn, height: Self.topHeight)
                details
                    .padding(.top, 20)
                    .padding(.leading, 20)
                    .padding(.trailing, 16)
                Spacer(minLength: 0)
            }
            .frame(height: Self.topHeight)
            .overlay(alignment: .leading) {
                DashedLine(vertical: true)
                    .stroke(dashColor, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(width: 1)
                    .padding(.leading, tileColumn)
                    .padding(.top, 14)
            }

            DashedLine(vertical: false)
                .stroke(dashColor, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .frame(height: 1)

            HStack {
                Text("Your place is saved")
                    .scaledFont(15, maxScale: 1.3)
                    .foregroundStyle(Theme.secondary)
                Spacer(minLength: 8)
                Button(action: onViewConfirmation) {
                    Text("View ticket")
                        .scaledFont(15, weight: .semibold, maxScale: 1.3)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .gatherGlass(in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .frame(maxHeight: .infinity)
        }
        .frame(height: Self.cardHeight)
        .background(Theme.pink)
        .clipShape(.rect(cornerRadius: 28))
    }

    private var dateTile: some View {
        VStack(spacing: 2) {
            Text(event.month)
                .scaledFont(13, weight: .bold, maxScale: 1.2)
                .foregroundStyle(warmText)
            Capsule().fill(Theme.pink).frame(width: 20, height: 4)
            Text(event.day.formatted(.number.precision(.integerLength(2...))))
                .scaledFont(36, weight: .heavy, maxScale: 1.2)
                .foregroundStyle(Theme.ink)
            Text(event.weekday)
                .scaledFont(12, maxScale: 1.2)
                .foregroundStyle(Theme.gatherText)
        }
        .frame(width: 72, height: 86)
        .background(Theme.surface, in: .rect(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        .rotationEffect(.degrees(-6))
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.title)
                .scaledFont(24, weight: .heavy, maxScale: 1.2)
                .tracking(-0.6)
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                Text(event.time)
                Rectangle().fill(Theme.ink.opacity(0.35)).frame(width: 1, height: 14).padding(.horizontal, 2)
                Image(systemName: "mappin.circle.fill")
                Text(event.locality).lineLimit(1)
            }
            .scaledFont(14, maxScale: 1.2)
            .foregroundStyle(warmText)

            Text("By \(event.host)")
                .scaledFont(14, maxScale: 1.2)
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Shown when there are no registrations yet

struct EmptyTicketCard: View {
    private let tileColumn: CGFloat = 114
    private let dashColor = Theme.ink.opacity(0.22)
    private let warmText = Color.adaptive(0x9C4A4B, 0xF0ADAA)

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                emblem
                    .frame(width: tileColumn, height: TicketCard.topHeight)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nothing booked yet")
                        .scaledFont(22, weight: .heavy, maxScale: 1.2)
                        .tracking(-0.5)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    Text("Reserve a spot and your ticket will show up here.")
                        .scaledFont(14, maxScale: 1.2)
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(3)
                }
                .padding(.leading, 20)
                .padding(.trailing, 16)
                Spacer(minLength: 0)
            }
            .frame(height: TicketCard.topHeight)
            .overlay(alignment: .leading) {
                DashedLine(vertical: true)
                    .stroke(dashColor, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(width: 1)
                    .padding(.leading, tileColumn)
                    .padding(.top, 14)
            }

            DashedLine(vertical: false)
                .stroke(dashColor, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .frame(height: 1)

            HStack(spacing: 8) {
                Text("Free spots can be cancelled anytime")
                    .scaledFont(13, maxScale: 1.3)
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .frame(maxHeight: .infinity)
        }
        .frame(height: TicketCard.cardHeight)
        .background(Theme.pink)
        .clipShape(.rect(cornerRadius: 28))
        .accessibilityElement(children: .combine)
    }

    private var emblem: some View {
        Image(systemName: "ticket.fill")
            .font(.system(size: 34, weight: .semibold))
            .foregroundStyle(warmText)
            .frame(width: 72, height: 86)
            .background(Theme.surface, in: .rect(cornerRadius: 18))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            .rotationEffect(.degrees(-6))
            .accessibilityHidden(true)
    }
}

// MARK: - "Find your next outing" card

struct OutingCard: View {
    let event: Event
    var coverHeight: CGFloat = 146

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EventCover(event: event)
                .frame(height: coverHeight)
                .clipShape(.rect(cornerRadius: 20))
                .overlay(alignment: .topTrailing) {
                    if event.isHostedByMe {
                        Label(event.unansweredCount > 0 ? "Hosting · \(event.unansweredCount) new" : "Hosting",
                              systemImage: "star.fill")
                            .scaledFont(13, weight: .semibold, maxScale: 1.2)
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Theme.pink))
                            .padding(8)
                    } else if event.isRegistered {
                        Label("Registered", systemImage: "checkmark.circle.fill")
                            .scaledFont(13, weight: .semibold, maxScale: 1.2)
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Theme.lavender))
                            .padding(8)
                    }
                }
                .overlay(alignment: .topLeading) {
                    Label(event.normalizedCategory, systemImage: event.symbol)
                        .scaledFont(13, weight: .medium, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.surface))
                        .padding(8)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .scaledFont(17, weight: .bold, maxScale: 1.2)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                GatherInfoRow(icon: "calendar", text: event.shortDateText)
                GatherInfoRow(icon: "person.2.fill", text: event.ages)
                if coverHeight > 146 {
                    GatherInfoRow(icon: "mappin.and.ellipse",
                                  text: event.mode == .online ? "Online" : event.locality)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
        }
        .padding(6)
        .background(Theme.surface, in: .rect(cornerRadius: 26))
        .roundedStroke(Theme.lilacBorder, cornerRadius: 26, lineWidth: 1)
    }
}
