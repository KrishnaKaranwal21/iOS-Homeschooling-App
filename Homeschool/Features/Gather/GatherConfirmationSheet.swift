import SwiftUI

struct EventAttendingBadge: View {
    var title = "Going"

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(hex: 0x83CDB3))
            Text(title).foregroundStyle(.white)
        }
        .scaledFont(13, weight: .semibold, maxScale: 1.3)
        .padding(.horizontal, 11).padding(.vertical, 8)
        .background(Color(hex: 0x202123), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

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

/// The saved registration remains available from the event, feed and tickets.
struct GatherConfirmationSheet: View {
    let event: Event
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var showCalendar = false
    @State private var calendarSaved = false
    @State private var confirmCancel = false
    @State private var showHost = false
    @State private var showProfilePrompt = false
    @State private var openProfileAfterPrompt = false
    @State private var showProfile = false
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var current: Event { state.events.first { $0.id == event.id } ?? event }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    EventCover(event: current)
                        .frame(height: sizeClass == .regular ? 300 : 200)
                        .clipShape(GatherWaveShape())
                        .overlay(alignment: .bottomLeading) {
                            EventAttendingBadge().offset(y: 6)
                        }
                        .padding(.horizontal, 12).padding(.bottom, 12)
                    Text(current.title)
                        .scaledFont(27, weight: .bold, maxScale: 1.35)
                        .tracking(-0.7).foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    VStack(alignment: .leading, spacing: 17) {
                        summaryRow("clock", text: "\(current.start.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))) at \(current.time)")
                        if current.mode == .online {
                            if let url = current.onlineURL {
                                Link(destination: url) { summaryRow("video", text: "Join online event") }
                            } else {
                                summaryRow("video", text: "No event link added")
                            }
                        } else {
                            summaryRow("mappin.and.ellipse", text: current.location.replacingOccurrences(of: "\n", with: ", "))
                        }
                    }
                    Button { showCalendar = true } label: {
                        Text(calendarSaved ? "Added to calendar" : "Add to calendar")
                            .scaledFont(17, weight: .semibold, maxScale: 1.3)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .foregroundStyle(Color.adaptive(0xFFFFFF, 0x171719))
                            .background(Color.adaptive(0x333238, 0xF1F0F4), in: Capsule())
                    }
                    .buttonStyle(.plain).accessibilityIdentifier("event.confirmation.calendar")

                    NavigationLink {
                        RegistrationDetailView(event: current, registration: state.registrations[current.id])
                    } label: {
                        Label("View registration details", systemImage: "ticket")
                            .scaledFont(15, weight: .semibold, maxScale: 1.3)
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Theme.field, in: Capsule())
                    }.buttonStyle(.plain)

                    organizerSuggestion

                    if state.canCancel(current) {
                        Button("Cancel my place", role: .destructive) { confirmCancel = true }
                            .font(.subheadline.weight(.medium)).frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 24)
                .frame(maxWidth: 680).frame(maxWidth: .infinity)
            }
            .background(Theme.background.ignoresSafeArea())
            .safeAreaInset(edge: .top, spacing: 0) { header }
            .safeAreaInset(edge: .bottom, spacing: 0) { goingBar }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showHost) { HostEventView().toolbarVisibility(.visible, for: .navigationBar) }
            .navigationDestination(isPresented: $showProfile) { ProfileView() }
            .sheet(isPresented: $showCalendar) {
                EventCalendarSheet(event: current, onSaved: { calendarSaved = true }).ignoresSafeArea()
            }
            .sheet(isPresented: $showProfilePrompt, onDismiss: {
                if openProfileAfterPrompt {
                    openProfileAfterPrompt = false
                    showProfile = true
                }
            }) {
                CompleteProfileSheet(missing: state.missingProfileItems) {
                    openProfileAfterPrompt = true
                    showProfilePrompt = false
                }
            }
            .confirmationDialog("Cancel your place?", isPresented: $confirmCancel, titleVisibility: .visible) {
                Button("Cancel my place", role: .destructive) {
                    if state.cancelRegistration(for: current) { dismiss() }
                }
                Button("Keep my place", role: .cancel) {}
            } message: {
                Text("Your spot at \(current.title) will be released.")
            }
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 21, weight: .light))
                    .foregroundStyle(Theme.ink).frame(width: 44, height: 44)
                    .gatherGlass(in: Circle())
            }.buttonStyle(.plain).accessibilityLabel("Back to event")
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(Theme.background.opacity(0.97))
    }

    private var organizerSuggestion: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Organize your own event").scaledFont(15, weight: .semibold, maxScale: 1.3).foregroundStyle(Theme.ink)
                Text("Bring your learning community together.").scaledFont(13, maxScale: 1.3).foregroundStyle(Theme.secondary)
            }
            Spacer(minLength: 0)
            Button {
                if state.missingProfileItems.isEmpty { showHost = true } else { showProfilePrompt = true }
            } label: {
                Text("Create").scaledFont(13, weight: .semibold, maxScale: 1.3)
                    .foregroundStyle(Theme.ink).padding(.horizontal, 17).frame(minHeight: 44)
                    .background(Theme.surface, in: Capsule())
            }.buttonStyle(.plain)
        }
        .padding(18).background(Theme.lilac, in: .rect(cornerRadius: 25))
    }

    private var goingBar: some View {
        HStack {
            Text("Going").scaledFont(17, weight: .semibold, maxScale: 1.3).foregroundStyle(Theme.ink)
                .padding(.leading, 18)
            Spacer()
            ShareLink(item: "\(current.title)\n\(current.shortDateText)\n\(current.location)") {
                Label("Share", systemImage: "square.and.arrow.up")
                    .scaledFont(16, weight: .semibold, maxScale: 1.3)
                    .foregroundStyle(Theme.ink).padding(.horizontal, 28).frame(minHeight: 48)
                    .background(Theme.lavender, in: Capsule())
            }.buttonStyle(.plain)
        }
        .padding(6).background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.ink.opacity(0.12), lineWidth: 1))
        .padding(.horizontal, 20).padding(.vertical, 8)
    }

    private func summaryRow(_ icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.system(size: 17, weight: .regular)).frame(width: 22)
            Text(text).scaledFont(15, maxScale: 1.35).fixedSize(horizontal: false, vertical: true)
        }.foregroundStyle(Theme.secondary)
    }
}
