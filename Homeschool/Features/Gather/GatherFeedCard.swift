import SwiftUI

struct GatherFeedCard: View {
    let event: Event
    @Environment(AppState.self) private var state
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showTicket = false

    private var locationSummary: String {
        if event.mode == .online { return "Online" }
        if state.usesLiveLocation,
           let distance = state.eventLocations.distanceText(for: event, from: state.locationService.lastLocation) {
            return distance
        }
        return event.locality
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                NavigationLink(value: event) {
                    EventCover(event: event)
                        .aspectRatio(1.87, contentMode: .fit)
                        .clipShape(.rect(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View \(event.title)")
                .overlay(alignment: .topLeading) {
                    if event.isHostedByMe {
                        EventAttendingBadge(title: "Hosting", symbol: "star.circle.fill", tint: Color(hex: 0x7457C8))
                            .padding(12).allowsHitTesting(false)
                    } else if event.isRegistered {
                        EventAttendingBadge(title: "Attending").padding(12).allowsHitTesting(false)
                    }
                }
                HStack(spacing: 0) {
                    ShareLink(item: "\(event.title)\n\(event.shortDateText)\n\(event.location)\nHosted by \(event.host)") {
                        Image(systemName: "square.and.arrow.up").frame(width: 42, height: 42)
                    }.accessibilityLabel("Share \(event.title)")
                    Button { state.toggleBookmark(event) } label: {
                        Image(systemName: state.isBookmarked(event) ? "heart.fill" : "heart")
                            .foregroundStyle(state.isBookmarked(event) ? Color(hex: 0xF3A7C3) : .white)
                            .frame(width: 42, height: 42)
                    }
                    .accessibilityLabel(state.isBookmarked(event) ? "Unsave \(event.title)" : "Save \(event.title)")
                    .sensoryFeedback(.selection, trigger: state.isBookmarked(event))
                }
                .scaledFont(19, maxScale: 1.35).foregroundStyle(.white)
                .background(.black.opacity(0.55), in: .rect(cornerRadius: 14))
                .buttonStyle(.plain).padding(12)
            }
            NavigationLink(value: event) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(event.title).scaledFont(18, weight: .semibold, maxScale: 1.35)
                        .foregroundStyle(Theme.ink).lineLimit(2, reservesSpace: sizeClass == .regular)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 7) {
                        Text(event.feedDateText())
                            .scaledFont(12, maxScale: 1.35).foregroundStyle(Theme.secondary)
                            .lineLimit(1).minimumScaleFactor(0.85)
                        EventModeBadge(mode: event.mode)
                    }
                    Text(event.mode == .online ? "by \(event.host)" : "\(locationSummary) • by \(event.host)")
                        .scaledFont(12, maxScale: 1.35).foregroundStyle(Theme.secondary)
                        .lineLimit(1).truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
            }.buttonStyle(.plain)
            // Only shown once someone is going (or you are). No "be the first" prompt, no "Hosting" label here.
            if event.isRegistered || event.registeredCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: event.isRegistered ? "checkmark.circle.fill" : "person.2")
                        .foregroundStyle(Theme.accent).accessibilityHidden(true)
                    if event.isRegistered {
                        Button("You’re going · View ticket") { showTicket = true }
                            .foregroundStyle(Theme.accent).buttonStyle(.plain)
                    } else {
                        Text("\(event.registeredCount) going")
                            .foregroundStyle(Theme.ink)
                    }
                    Spacer(minLength: 0)
                }
                .scaledFont(12, weight: .semibold, maxScale: 1.35).frame(minHeight: 24)
            }
        }
        .padding(12)
        .background(Theme.surface, in: .rect(cornerRadius: 28))
        .roundedStroke(Theme.lilacBorder, cornerRadius: 28)
        .fullScreenCover(isPresented: $showTicket) { BookingTicketView(event: event) }
        .task(id: state.locationService.lastLocation?.timestamp) {
            guard state.usesLiveLocation, state.locationService.lastLocation != nil else { return }
            _ = await state.eventLocations.resolve(event)
        }
    }
}

/// The same geometry as a loaded event card; no fabricated rows or counts.
struct GatherLoadingCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shimmering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            RoundedRectangle(cornerRadius: 18).aspectRatio(1.87, contentMode: .fit)
                .padding(.bottom, 6)
            Capsule().frame(height: 16).frame(maxWidth: .infinity).padding(.trailing, 65)
            Capsule().frame(width: 185, height: 13)
            Capsule().frame(width: 164, height: 10)
            Capsule().frame(width: 145, height: 10)
            HStack(spacing: -3) {
                ForEach(0..<3) { _ in Circle().frame(width: 25, height: 25) }
                Capsule().frame(width: 53, height: 9).padding(.leading, 16)
            }.padding(.top, 9)
        }
        .foregroundStyle(Theme.loadingFill)
        .overlay {
            if !reduceMotion {
                GeometryReader { geometry in
                    LinearGradient(colors: [.clear, Theme.ink.opacity(0.055), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: shimmering ? geometry.size.width : -geometry.size.width * 0.6)
                }
                .mask {
                    VStack(alignment: .leading, spacing: 9) {
                        RoundedRectangle(cornerRadius: 18).aspectRatio(1.87, contentMode: .fit).padding(.bottom, 6)
                        Capsule().frame(height: 16).padding(.trailing, 65)
                        Capsule().frame(width: 185, height: 13)
                        Capsule().frame(width: 164, height: 10)
                        Capsule().frame(width: 145, height: 10)
                        HStack(spacing: -3) {
                            ForEach(0..<3) { _ in Circle().frame(width: 25, height: 25) }
                            Capsule().frame(width: 53, height: 9).padding(.leading, 16)
                        }.padding(.top, 9)
                    }
                }
            }
        }
        .padding(12)
        .background(Theme.surface, in: .rect(cornerRadius: 28))
        .roundedStroke(Theme.lilacBorder, cornerRadius: 28)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) { shimmering = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading more events")
        .accessibilityIdentifier("gather.loading")
    }
}

/// Native event artwork remains sharp at every device size and in either appearance.
/// Hosts' photos take precedence over this editorial cover.
/// Uses the app's own font and soft, light colours in both appearances.
struct GatherEventPoster: View {
    let event: Event

    private var palette: (background: Color, accent: Color) { event.artPalette }
    private let ink = Event.artInk
    private var headline: String {
        switch event.normalizedCategory {
        case "Nature": "A little wonder.\nA world outside."
        case "Art": "Make a mess.\nMake something\nmarvellous."
        case "Music": "Find the rhythm.\nPlay together."
        case "Sports": "Run, jump,\nplay and grow."
        default: "Little questions.\nBig discoveries."
        }
    }
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let colors = palette
            ZStack(alignment: .topLeading) {
                colors.background
                VStack(alignment: .leading, spacing: 0) {
                    // The top line is no longer shown, but it still holds its space so the artwork keeps its layout.
                    Text("Homeschool")
                        .font(.system(size: max(8, size.width * 0.028), weight: .semibold))
                        .hidden()
                    Spacer(minLength: 8)
                    Text(headline)
                        .font(.system(size: max(16, size.width * 0.06), weight: .heavy))
                        .tracking(-0.5).foregroundStyle(ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: size.width * 0.62, alignment: .leading)
                    Spacer(minLength: 8)
                    Text("Come curious. Leave inspired.")
                        .font(.system(size: max(7, size.width * 0.026), weight: .medium))
                        .foregroundStyle(ink.opacity(0.65))
                }
                .padding(size.width * 0.055)
                .frame(maxHeight: .infinity)
                RoundedRectangle(cornerRadius: size.width * 0.03)
                    .fill(colors.accent.opacity(0.7))
                    .frame(width: size.width * 0.25, height: size.height * 0.28)
                    .position(x: size.width * 0.88, y: size.height * 0.86)
                Circle().fill(colors.accent)
                    .frame(width: size.width * 0.29, height: size.width * 0.29)
                    .overlay {
                        Image(systemName: event.symbol).font(.system(size: size.width * 0.105, weight: .regular))
                            .foregroundStyle(ink)
                    }
                    .position(x: size.width * 0.86, y: size.height * 0.48)
                Circle().fill(colors.accent.opacity(0.8))
                    .frame(width: size.width / 15, height: size.width / 15)
                    .position(x: size.width * 0.62, y: size.height * 0.84)
            }
        }
        .clipped().accessibilityHidden(true)
    }
}

extension Event {
    /// Soft pastel colours for each category, shared by the poster and the small icon tile.
    var artPalette: (background: Color, accent: Color) {
        switch normalizedCategory {
        case "Nature": (Color(hex: 0xDDF3E8), Color(hex: 0x9ADBBB))
        case "Art":    (Color(hex: 0xFCE4DB), Color(hex: 0xF5B09B))
        case "Music":  (Color(hex: 0xFDE3EE), Color(hex: 0xF4A9C8))
        case "Sports": (Color(hex: 0xE1EAFF), Color(hex: 0xA9C3FF))
        default:       (Color(hex: 0xEBE5FF), Color(hex: 0xC9B6FF))
        }
    }
    /// Soft purple-grey ink, readable on every pastel above without being near-black.
    static let artInk = Color(hex: 0x4B4570)
}

/// A small square showing only the event's category icon (the book for Study, the leaf for Nature...).
struct EventIconTile: View {
    let event: Event

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                event.artPalette.background
                Circle().fill(event.artPalette.accent)
                    .frame(width: side * 0.62, height: side * 0.62)
                    .overlay {
                        Image(systemName: event.symbol)
                            .font(.system(size: side * 0.28, weight: .regular))
                            .foregroundStyle(Event.artInk)
                    }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityHidden(true)
    }
}
