import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Environment(AppState.self) private var state
    @State private var showConfirmation = false

    /// Latest copy from the app state, so the Register button reflects a new registration.
    private var current: Event {
        state.events.first { $0.id == event.id } ?? event
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                cover
                titleRow
                    .padding(.top, -14)
                infoCard
                hostCard
                if !current.isFree {
                    Label("Paid events are non-refundable, even if you don't attend.",
                          systemImage: "exclamationmark.triangle.fill")
                        .scaledFont(15, weight: .medium, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.chipFill))
                }
                Text(current.about)
                    .scaledFont(16, maxScale: 1.3)
                    .lineSpacing(4)
                    .foregroundStyle(Theme.gatherText)
                    .padding(.horizontal, 6)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { state.toggleBookmark(current) } label: {
                    Image(systemName: state.isBookmarked(current) ? "bookmark.fill" : "bookmark")
                }
                .sensoryFeedback(.selection, trigger: state.isBookmarked(current))
                .accessibilityLabel(state.isBookmarked(current) ? "Remove from saved events" : "Save event")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .sheet(isPresented: $showConfirmation) { GatherConfirmationSheet(event: current) }
    }

    // MARK: Pieces

    private var cover: some View {
        EventCover(event: current)
            .frame(height: 240)
            .clipShape(GatherWaveShape())
            .overlay(alignment: .topLeading) {
                Label(current.kind.rawValue, systemImage: "person.2.fill")
                    .scaledFont(15, weight: .medium, maxScale: 1.2)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Theme.lilac))
                    .padding(12)
            }
    }

    private var titleRow: some View {
        HStack(alignment: .top, spacing: 14) {
            dateTile
            VStack(alignment: .leading, spacing: 4) {
                Text(current.title)
                    .scaledFont(30, weight: .heavy, maxScale: 1.2)
                    .tracking(-1)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text("\(current.mode.rawValue) · \(current.ages)")
                    .scaledFont(16, maxScale: 1.3)
                    .foregroundStyle(Theme.gatherText)
            }
            .padding(.top, 22)
        }
    }

    private var dateTile: some View {
        VStack(spacing: 0) {
            Text(current.month)
                .scaledFont(16, weight: .semibold, maxScale: 1.2)
                .foregroundStyle(Color(hex: 0xE5737A))
            Text(current.day.formatted(.number.precision(.integerLength(2...))))
                .scaledFont(40, weight: .heavy, maxScale: 1.2)
                .foregroundStyle(Theme.ink)
            Text(current.weekday)
                .scaledFont(16, maxScale: 1.2)
                .foregroundStyle(Theme.gatherText)
        }
        .frame(width: 88, height: 98)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Theme.lilacBorder, lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }

    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow(icon: "clock.fill",
                    title: current.start.formatted(.dateTime.weekday(.wide).day().month(.abbreviated).year()),
                    detail: "\(current.time) – \(current.end.formatted(date: .omitted, time: .shortened))")

            Rectangle().fill(Theme.lilacBorder).frame(height: 1).padding(.leading, 72)

            if current.mode == .online {
                infoRow(icon: "video.fill", title: "Online event", detail: "The link is shared after you register")
            } else {
                Link(destination: mapsURL) {
                    infoRow(icon: "mappin", title: current.locationLines.title,
                            detail: current.locationLines.detail, showsChevron: true)
                }
                .buttonStyle(.plain)
            }

            Rectangle().fill(Theme.lilacBorder).frame(height: 1).padding(.leading, 72)

            infoRow(icon: current.parentPresence.symbol,
                    title: current.parentPresence.rawValue,
                    detail: current.parentPresence.detail)
        }
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Theme.lilac))
    }

    private func infoRow(icon: String, title: String, detail: String?, showsChevron: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .scaledFont(18, maxScale: 1.2)
                .foregroundStyle(Theme.gatherText)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Color.white))
                .overlay(Circle().stroke(Theme.lilacBorder, lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .scaledFont(17, weight: .medium, maxScale: 1.3)
                    .foregroundStyle(Theme.ink)
                if let detail {
                    Text(detail)
                        .scaledFont(15, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                }
            }
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.gatherText)
            }
        }
        .padding(14)
        .contentShape(Rectangle())
    }

    private var hostCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.fill")
                .scaledFont(20, maxScale: 1.2)
                .foregroundStyle(Theme.gatherText)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Color.white.opacity(0.8)))

            VStack(alignment: .leading, spacing: 2) {
                Text("Hosted by \(current.host)")
                    .scaledFont(17, weight: .medium, maxScale: 1.3)
                    .foregroundStyle(Theme.ink)
                Text(current.hostRole)
                    .scaledFont(15, maxScale: 1.3)
                    .foregroundStyle(Theme.gatherText)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Theme.pink.opacity(0.65)))
    }

    private var bottomBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(current.priceText)
                    .scaledFont(26, weight: .bold, maxScale: 1.2)
                    .foregroundStyle(Theme.ink)
                Text(priceCaption)
                    .scaledFont(15, maxScale: 1.3)
                    .foregroundStyle(Theme.gatherText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .layoutPriority(-1)
            Spacer(minLength: 8)

            if current.isRegistered {
                Button { showConfirmation = true } label: {
                    Label("Registered", systemImage: "checkmark.circle.fill")
                        .scaledFont(17, weight: .semibold, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 20)
                        .frame(minHeight: 56)
                        .gatherGlass(in: Capsule(), tint: Theme.lilac)
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink { RegistrationView(event: current) } label: {
                    Text("Register")
                        .scaledFont(17, weight: .semibold, maxScale: 1.2)
                        .foregroundStyle(Color.white)
                        .frame(width: 160)
                        .frame(minHeight: 56)
                        .gatherGlass(in: Capsule(), tint: Theme.ink)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.08), radius: 16, y: 4))
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    private var priceCaption: String {
        guard current.isRegistered else { return current.isFree ? current.kind.rawValue : "No refunds" }
        return state.canCancel(current) ? "Cancel any time" : "Paid · no refunds"
    }

    private var mapsURL: URL {
        let query = current.location.replacingOccurrences(of: "\n", with: ", ")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://maps.apple.com/?q=\(query)") ?? URL(string: "https://maps.apple.com")!
    }
}
