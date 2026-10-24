import SwiftUI
import UIKit

// MARK: - Cover image

extension Event {
    /// Colour used when an event has no photo yet.
    var tint: Color {
        switch category {
        case "Nature":  return Color(hex: 0x7FA777)
        case "Art":     return Color(hex: 0xE8A07F)
        case "Science": return Color(hex: 0x8FA8E8)
        case "Habit":   return Color(hex: 0xE59AA0)
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
        if let data = event.coverData, let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill()
        } else if let name = event.coverName, UIImage(named: name) != nil {
            Image(name).resizable().scaledToFill()
        } else {
            ZStack {
                LinearGradient(colors: [event.tint.opacity(0.6), event.tint],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: event.symbol)
                    .font(.system(size: 56))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
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
        .background(Capsule().fill(Color.white))
        .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
    }
}

// MARK: - Date and time fields

/// Tap to open a calendar. Choosing a day saves it and closes the calendar.
struct GatherDateField: View {
    @Binding var date: Date
    @State private var isPresented = false

    private var binding: Binding<Date> {
        Binding(get: { date }, set: { newValue in
            date = newValue
            isPresented = false
        })
    }

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
            DatePicker("Date", selection: binding, in: Date.now..., displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(12)
                .frame(width: 330)
                .presentationCompactAdaptation(.popover)
        }
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

private struct DashedLine: Shape {
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
    private let dashColor = Color.black.opacity(0.22)
    private let warmText = Color(hex: 0x9C4A4B)

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                dateTile
                    .frame(width: tileColumn, height: 128)
                details
                    .padding(.top, 20)
                    .padding(.trailing, 16)
                Spacer(minLength: 0)
            }
            .frame(height: 128)
            .overlay(alignment: .leading) {
                DashedLine(vertical: true)
                    .stroke(dashColor, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(width: 1)
                    .padding(.leading, tileColumn)
                    .padding(.vertical, 12)
            }

            DashedLine(vertical: false)
                .stroke(dashColor, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .frame(height: 1)

            HStack {
                Text("Your place is saved")
                    .scaledFont(15, maxScale: 1.3)
                    .foregroundStyle(Color.black.opacity(0.45))
                Spacer(minLength: 8)
                Button(action: onViewConfirmation) {
                    Text("View Confirmation")
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
        .frame(height: 172)
        .background(Theme.pink)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .mask { notches }
    }

    /// Half-circle bites out of the left and right edges, like a paper ticket.
    private var notches: some View {
        Rectangle()
            .overlay(alignment: .leading) {
                Circle().frame(width: 26, height: 26).offset(x: -13).blendMode(.destinationOut)
            }
            .overlay(alignment: .trailing) {
                Circle().frame(width: 26, height: 26).offset(x: 13).blendMode(.destinationOut)
            }
            .compositingGroup()
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
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white))
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
                Rectangle().fill(Color.black.opacity(0.35)).frame(width: 1, height: 14).padding(.horizontal, 2)
                Image(systemName: "mappin.circle.fill")
                Text(event.locality).lineLimit(1)
            }
            .scaledFont(14, maxScale: 1.2)
            .foregroundStyle(warmText)

            Text("By \(event.host)")
                .scaledFont(14, maxScale: 1.2)
                .foregroundStyle(Color.black.opacity(0.45))
                .lineLimit(1)
        }
    }
}

// MARK: - "Find your next outing" card

struct OutingCard: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EventCover(event: event)
                .frame(height: 146)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(alignment: .topLeading) {
                    Label(event.category, systemImage: event.symbol)
                        .scaledFont(13, weight: .medium, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white))
                        .padding(8)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .scaledFont(17, weight: .bold, maxScale: 1.2)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                GatherInfoRow(icon: "calendar", text: event.shortDateText)
                GatherInfoRow(icon: "person.2.fill", text: event.ages)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Theme.lilacBorder, lineWidth: 1))
    }
}

// MARK: - Confirmation sheet

/// Summary of a saved place, with a button to see everything that was submitted.
struct GatherConfirmationSheet: View {
    let event: Event
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.green)
                    .padding(.top, 12)

                VStack(spacing: 6) {
                    Text("Your place is saved")
                        .scaledFont(26, weight: .heavy, maxScale: 1.3)
                        .foregroundStyle(Theme.ink)
                    Text(event.title)
                        .scaledFont(17, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                    if let registration = state.registrations[event.id] {
                        Text("Reference \(registration.code)")
                            .scaledFont(14, weight: .medium, maxScale: 1.3)
                            .foregroundStyle(Theme.gatherText)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    GatherInfoRow(icon: "calendar",
                                  text: event.start.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                    GatherInfoRow(icon: "clock",
                                  text: "\(event.time) – \(event.end.formatted(date: .omitted, time: .shortened))")
                    GatherInfoRow(icon: "mappin.and.ellipse", text: event.locationLines.title)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.lilac))

                NavigationLink {
                    RegistrationDetailView(event: event, registration: state.registrations[event.id])
                } label: {
                    Label("View registration details", systemImage: "doc.text")
                        .scaledFont(16, weight: .semibold, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherAccent)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .gatherGlass(in: Capsule())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                PrimaryButton(title: "Done") { dismiss() }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            .background(Theme.background)
            .toolbarVisibility(.hidden, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
    }
}

/// Everything about the event and what was submitted for it.
struct RegistrationDetailView: View {
    let event: Event
    let registration: Registration?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let registration {
                    group("Registration", rows: [
                        ("Reference", registration.code),
                        ("Registered on", registration.registeredAt.formatted(date: .abbreviated, time: .shortened))
                    ])
                }

                group("Event", rows: [
                    ("Event", event.title),
                    ("Date", event.start.formatted(.dateTime.weekday(.wide).day().month(.wide).year())),
                    ("Time", "\(event.time) – \(event.end.formatted(date: .omitted, time: .shortened))"),
                    ("Where", event.mode == .online ? "Online" : event.location.replacingOccurrences(of: "\n", with: ", ")),
                    ("Hosted by", event.host),
                    ("Ages", event.ages),
                    ("Price", event.priceText)
                ])

                if let registration {
                    let details = registration.registrant
                    group("Parent or guardian", rows: [
                        ("Name", details.parentName),
                        ("Email", details.email),
                        ("Mobile", details.mobile)
                    ])
                    group("Little explorer", rows: [
                        ("Name", details.childName),
                        ("Age", details.childAge),
                        ("Notes", details.notes.isEmpty ? "None" : details.notes)
                    ])
                }
            }
            .padding(20)
        }
        .background(Theme.background)
        .navigationTitle("Registration details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func group(_ title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .scaledFont(18, weight: .bold, maxScale: 1.3)
                .foregroundStyle(Theme.ink)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(row.0)
                            .scaledFont(15, maxScale: 1.3)
                            .foregroundStyle(Theme.gatherText)
                            .frame(width: 104, alignment: .leading)
                        Text(row.1.isEmpty ? "—" : row.1)
                            .scaledFont(16, weight: .medium, maxScale: 1.3)
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)

                    if index < rows.count - 1 {
                        Rectangle().fill(Theme.cardBorder).frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.lilacBorder, lineWidth: 1))
        }
    }
}
