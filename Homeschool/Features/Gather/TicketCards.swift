import SwiftUI
import UniformTypeIdentifiers

// MARK: - TicketCard

/// A booked event shown as a ticket: date tile, title, time and a link to the confirmation.
struct TicketCard: View {
    let event: Event
    let onViewConfirmation: () -> Void

    private let tileColumn: CGFloat = 114
    private let dashColor = Theme.ink.opacity(0.22)
    private let warmText = Color(hex: 0x9C4A4B)
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

// MARK: - EmptyTicketCard

/// The placeholder ticket shown when nothing is booked yet.
struct EmptyTicketCard: View {
    private let tileColumn: CGFloat = 114
    private let dashColor = Theme.ink.opacity(0.22)
    private let warmText = Color(hex: 0x9C4A4B)

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
            .scaledFont(34, weight: .semibold)
            .foregroundStyle(warmText)
            .frame(width: 72, height: 86)
            .background(Theme.surface, in: .rect(cornerRadius: 18))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            .rotationEffect(.degrees(-6))
            .accessibilityHidden(true)
    }
}

// MARK: - OutingCard

/// A compact event card with a cover image, used in lists of outings.
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

// MARK: - BookingTicketCard

/// The ticket body of `BookingTicketView`: event details, booking reference and QR code.
struct BookingTicketCard: View {
    let event: Event
    let registration: Registration
    let qrImage: Image?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Group {
                if let qrImage {
                    qrImage.interpolation(.none).resizable().scaledToFit()
                        .accessibilityLabel("Booking QR code. Reference \(registration.code)")
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityLabel("Preparing booking QR code")
                }
            }
            .frame(maxWidth: 184).aspectRatio(1, contentMode: .fit).padding(8).background(.white, in: .rect(cornerRadius: 10))
            .frame(maxWidth: .infinity).padding(.top, 40).padding(.bottom, 8)

            DashedLine(vertical: false).stroke(Theme.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
                .frame(height: 1).padding(.vertical, 4)
            VStack(alignment: .leading, spacing: 7) {
                Text(event.title).scaledFont(19, weight: .bold, maxScale: 1.35).foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(event.mode == .online ? "Online event" : event.locationLines.title)
                    .scaledFont(14, maxScale: 1.35).foregroundStyle(Theme.secondary)
            }
            VStack(spacing: 12) {
                detail("Name", registration.registrant.parentName)
                detail("Group", event.host)
                detail("Date", event.start.formatted(.dateTime.day().month(.abbreviated).year()))
                detail("Time", event.timeWithZone)
                detail(registration.places == 1 ? "Learner" : "Learners", registration.registrant.childName)
                if registration.places > 1 { detail("Places", String(registration.places)) }
                detail("Booking", registration.code)
            }
            .padding(.top, 3)
        }
        .padding(.horizontal, 22).padding(.bottom, 30)
        .background(Theme.surface, in: TicketNotchShape())
        .overlay { TicketNotchShape().stroke(Theme.cardBorder.opacity(0.35), lineWidth: 0.5) }
        .accessibilityIdentifier("ticket.booking")
    }

    private func detail(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(label).foregroundStyle(Theme.secondary).frame(width: 65, alignment: .leading)
            Text(value.isEmpty ? "—" : value).foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .trailing).multilineTextAlignment(.trailing)
        }
        .scaledFont(13, maxScale: 1.35).fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - TicketNotchShape

/// A rounded rectangle with a semicircular notch cut into the top edge, like a torn ticket.
struct TicketNotchShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 20
        let notch: CGFloat = 32
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX - notch, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.midX, y: rect.minY), radius: notch, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
