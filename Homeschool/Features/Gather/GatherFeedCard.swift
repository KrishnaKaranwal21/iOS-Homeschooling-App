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
                        .clipShape(.rect(cornerRadius: 25))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View \(event.title)")
                .overlay(alignment: .topLeading) {
                    if event.isRegistered {
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
            HStack(spacing: 8) {
                Image(systemName: event.isRegistered ? "checkmark.circle.fill" : "person.2")
                    .foregroundStyle(Theme.accent).accessibilityHidden(true)
                if event.isRegistered {
                    Button("You’re going · View ticket") { showTicket = true }
                        .foregroundStyle(Theme.accent).buttonStyle(.plain)
                } else {
                    Text(event.registeredCount > 0 ? "\(event.registeredCount) going" : "Be the first to go")
                        .foregroundStyle(Theme.ink)
                }
                Spacer(minLength: 0)
                if event.isHostedByMe { Text("Hosting").foregroundStyle(Theme.accent) }
            }
            .scaledFont(12, weight: .semibold, maxScale: 1.35).frame(minHeight: 24)
        }
        .fullScreenCover(isPresented: $showTicket) { GatherConfirmationSheet(event: event) }
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
            RoundedRectangle(cornerRadius: 25).aspectRatio(1.87, contentMode: .fit)
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
                        RoundedRectangle(cornerRadius: 25).aspectRatio(1.87, contentMode: .fit).padding(.bottom, 6)
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
struct GatherEventPoster: View {
    let event: Event
    private var accent: Color {
        switch event.category {
        case "Nature": Color(hex: 0x67D6A2)
        case "Art": Color(hex: 0xF5A187)
        case "Science": Color(hex: 0x9EBBFF)
        case "Habit": Color(hex: 0xC4AEFF)
        default: Color(hex: 0x00D88A)
        }
    }
    private var headline: String {
        switch event.category {
        case "Nature": "A little wonder.\nA world outside."
        case "Art": "Make a mess.\nMake something\nmarvellous."
        case "Science": "Little questions.\nBig discoveries."
        case "Habit": "Small habits.\nBig possibilities."
        default: "Dream it.\nBuild it.\nTogether."
        }
    }
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack(alignment: .topLeading) {
                Color(hex: 0x182029)
                Canvas { context, canvas in
                    var grid = Path()
                    let step = max(20, canvas.width / 15)
                    for x in stride(from: CGFloat.zero, through: canvas.width, by: step) {
                        grid.move(to: CGPoint(x: x, y: 0)); grid.addLine(to: CGPoint(x: x, y: canvas.height))
                    }
                    for y in stride(from: CGFloat.zero, through: canvas.height, by: step) {
                        grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: canvas.width, y: y))
                    }
                    context.stroke(grid, with: .color(.white.opacity(0.13)), lineWidth: 0.6)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("HOMESCHOOL / \(event.category.uppercased())")
                        .font(.system(size: max(7, size.width * 0.021), weight: .semibold, design: .monospaced))
                        .tracking(1).foregroundStyle(accent)
                    Spacer(minLength: 8)
                    Text(headline)
                        .font(.system(size: max(16, size.width * 0.055), weight: .medium, design: .monospaced))
                        .tracking(-0.6).foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: size.width * 0.67, alignment: .leading)
                    Spacer(minLength: 8)
                    Text("COME CURIOUS. LEAVE INSPIRED.")
                        .font(.system(size: max(6, size.width * 0.019), weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.65)).tracking(0.6)
                }
                .padding(size.width * 0.055)
                .frame(maxHeight: .infinity)
                Rectangle().fill(accent)
                    .frame(width: size.width * 0.25, height: size.height * 0.28)
                    .position(x: size.width * 0.88, y: size.height * 0.86)
                Circle().fill(accent)
                    .frame(width: size.width * 0.29, height: size.width * 0.29)
                    .overlay {
                        Image(systemName: event.symbol).font(.system(size: size.width * 0.105, weight: .light))
                            .foregroundStyle(Color(hex: 0x182029))
                    }
                    .position(x: size.width * 0.86, y: size.height * 0.48)
                Rectangle().fill(accent.opacity(0.8))
                    .frame(width: size.width / 15, height: size.width / 15)
                    .position(x: size.width * 0.62, y: size.height * 0.84)
            }
        }
        .clipped().accessibilityHidden(true)
    }
}
