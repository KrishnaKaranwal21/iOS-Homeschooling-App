import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State var showConfirmation = false
    @State var showContactHost = false
    @State var showCalendar = false
    @State var calendarSaved = false
    @State var showOrganizerBanner = true
    @State var expandedAbout = false
    @State var expandedFAQs = false
    @State var descriptionFullHeight: CGFloat = 0
    @State var descriptionPreviewHeight: CGFloat = 0
    @State var showReport = false
    @State var reportSaved = false
    @State var reportNoticePending = false
    @State var showDetails = false
    @State var expandedQuestions = false
    @State var showHost = false
    @State var showProfile = false
    @State var showProfilePrompt = false
    @State var openProfileAfterPrompt = false

    var current: Event { state.events.first { $0.id == event.id } ?? event }
    var myQuestions: [EventQuestion] { current.questions.filter(\.askedByMe) }

    var body: some View {
        
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if showOrganizerBanner && !current.isHostedByMe { organizerBanner.padding(.top, 14) }
                    EventCover(event: current)
                        .frame(height: sizeClass == .regular ? 300 : 200)
                        .clipShape(GatherWaveShape())
                        .accessibilityHidden(true)
                    eventSummary
                    organizerCard
                    descriptionSection
                    if current.isHostedByMe {
                        hostPanel(proxy)
                        hostQuestionsSection.id("questions")
                    }
                    faqSection
                    if !current.isHostedByMe && !myQuestions.isEmpty {
                        DisclosureGroup(isExpanded: $expandedQuestions) { myQuestionsSection } label: {
                            Text("Your questions").font(.headline).foregroundStyle(Theme.ink)
                        }
                        .tint(Theme.accent).id("myQuestions")
                    }
                    EventLocationSection(event: current)
                    EventPhotosSection(event: current)
                    if !current.isHostedByMe{
                        reportButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background.ignoresSafeArea())
            .scrollBlurHeader { fixedHeader }
            .safeAreaInset(edge: .bottom, spacing: 0) { attendanceBar(proxy) }
            .navigationBarBackButtonHidden(true)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .toolbarVisibility(.hidden, for: .tabBar)
            .onAppear { state.tabBarHideCount += 1 }
            .onDisappear { state.tabBarHideCount = max(0, state.tabBarHideCount - 1) }
            .fullScreenCover(isPresented: $showConfirmation) { GatherConfirmationSheet(event: current) }
            .sheet(isPresented: $showContactHost) { ContactHostSheet(event: current) }
            .sheet(isPresented: $showReport, onDismiss: {
                if reportNoticePending {
                    reportNoticePending = false
                    reportSaved = true
                }
            }) {
                ReportEventSheet(event: current) {
                    reportNoticePending = true
                    showReport = false
                }
            }
            .alert("Report saved", isPresented: $reportSaved) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your report has been saved on this device.")
            }
            .sheet(isPresented: $showDetails) { detailsSheet }
            .sheet(isPresented: $showCalendar) { EventCalendarSheet(event: current, onSaved: { calendarSaved = true }).ignoresSafeArea() }
            .navigationDestination(isPresented: $showHost) { HostEventView().toolbarVisibility(.visible, for: .navigationBar) }
            .navigationDestination(isPresented: $showProfile) { ProfileView() }
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
            .task {
                guard state.scrollEventToQuestions else { return }
                state.scrollEventToQuestions = false
                expandedQuestions = true
                try? await Task.sleep(for: .milliseconds(350))
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                    proxy.scrollTo(current.isHostedByMe ? "questions" : "myQuestions", anchor: .top)
                }
            }
        }
    }

    var fixedHeader: some View {
        ZStack {
            Text("Event").scaledFont(17, weight: .bold, maxScale: 1.2)
                .foregroundStyle(Theme.ink).accessibilityAddTraits(.isHeader)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").accessibilityHidden(true).scaledFont(21, weight: .light)
                        .frame(width: 44, height: 44)
                        .gatherGlass(in: Circle())
                }.accessibilityLabel("Back to Gather")
                Spacer()
                HStack(spacing: 0) {
                    ShareLink(item: "\(current.title)\n\(current.fullDateText)\n\(current.timeRangeWithZone)\n\(current.location)") {
                        Image(systemName: "square.and.arrow.up").frame(width: 44, height: 44)
                    }.accessibilityLabel("Share event")
                    Button { state.toggleBookmark(current) } label: {
                        Image(systemName: state.isBookmarked(current) ? "heart.fill" : "heart")
                            .foregroundStyle(state.isBookmarked(current) ? Theme.accent : Theme.ink)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(state.isBookmarked(current) ? "Unsave event" : "Save event")
                    .sensoryFeedback(.selection, trigger: state.isBookmarked(current))
                }
                .scaledFont(20, weight: .light)
                .gatherGlass(in: Capsule())
            }
            .foregroundStyle(Theme.ink).buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 12)
    }

    var organizerBanner: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Become an organizer for free!")
                    .scaledFont(14, weight: .semibold, maxScale: 1.25).foregroundStyle(Theme.ink)
                Text("Create an event today!")
                    .scaledFont(13, maxScale: 1.25).foregroundStyle(Theme.secondary)
            }
            Spacer(minLength: 0)
            Button {
                if state.missingProfileItems.isEmpty { showHost = true } else { showProfilePrompt = true }
            } label: {
                Text("Create").scaledFont(12, weight: .semibold, maxScale: 1.25)
                    .foregroundStyle(Color(hex: 0xFFFFFF))
                    .padding(.horizontal, 18).frame(minHeight: 34)
                    .background(Color(hex: 0x7561D2), in: Capsule())
            }.buttonStyle(.plain)
        }
        .padding(16).frame(minHeight: 76)
        .background(LinearGradient(colors: [Theme.lilac, Theme.lavender.opacity(0.5)], startPoint: .leading, endPoint: .trailing), in: .rect(cornerRadius: 24))
        .overlay(alignment: .topTrailing) {
            Button { showOrganizerBanner = false } label: {
                Image(systemName: "xmark").scaledFont(10, weight: .medium)
                    .foregroundStyle(Theme.ink).frame(width: 28, height: 28)
                    .background(Theme.field, in: Circle())
            }.buttonStyle(.plain).offset(x: 6, y: -6)
                .accessibilityLabel("Dismiss organizer suggestion")
        }
    }

    var eventSummary: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(current.title).scaledFont(32, weight: .bold, maxScale: 1.3)
                .tracking(-0.9).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 14) {
                Image(systemName: "calendar").scaledFont(25, weight: .regular)
                    .foregroundStyle(Color(hex: 0xB8497B)).frame(width: 28)
                VStack(alignment: .leading, spacing: 6) {
                    Text(current.fullDateText).scaledFont(14, weight: .medium, maxScale: 1.35).foregroundStyle(Theme.ink)
                    HStack(spacing: 4) {
                        Text(current.timeRangeWithZone).scaledFont(13, maxScale: 1.35).foregroundStyle(Theme.secondary)
                        Button { showDetails = true } label: {
                            Image(systemName: "info.circle").scaledFont(12).foregroundStyle(Theme.secondary)
                                .frame(width: 28, height: 28)
                        }.buttonStyle(.plain).accessibilityLabel("Age guidance and parent requirements")
                    }
                }
                Spacer(minLength: 0)
                Button { showCalendar = true } label: {
                    Image(systemName: calendarSaved ? "calendar.badge.checkmark" : "calendar.badge.plus").scaledFont(20).foregroundStyle(Theme.ink)
                        .frame(width: 44, height: 44)
                }.buttonStyle(.plain).accessibilityLabel(calendarSaved ? "Event added to calendar. Add another copy" : "Add event to calendar")
            }
            Divider().overlay(Theme.cardBorder)
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: current.mode == .online ? "video.fill" : "mappin.and.ellipse")
                    .scaledFont(22, weight: .regular)
                    .foregroundStyle(Color(hex: 0x27846A)).frame(width: 28)
                VStack(alignment: .leading, spacing: 5) {
                    Text(current.mode == .online ? "Online event" : current.locationLines.title)
                        .scaledFont(14, weight: .medium, maxScale: 1.35).foregroundStyle(Theme.ink)
                    Text(current.mode == .online ? "The host shares joining details with attendees" : current.addressDetailText)
                        .scaledFont(13, maxScale: 1.35).foregroundStyle(Theme.secondary)
                }
            }
        }
    }

    var detailsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    practicalDetails
                }.padding(20)
            }
            .background(Theme.background)
            .navigationTitle("Event details").navigationBarTitleDisplayMode(.inline)
            .toolbarVisibility(.visible, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showDetails = false } } }
        }.presentationDragIndicator(.visible)
    }

    var practicalDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(current.ages, systemImage: "person.2").foregroundStyle(Theme.ink)
            Label(current.parentPresence.shortTitle, systemImage: current.parentPresence.symbol).foregroundStyle(Theme.ink)
            Text(current.parentPresence.detail).foregroundStyle(Theme.secondary)
        }
        .scaledFont(13, maxScale: 1.35)
        .padding(.top, 6)
    }

    func attendanceBar(_ proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 16) {
            Text(current.isHostedByMe ? "Hosting" : current.priceText)
                .scaledFont(17, weight: .semibold, maxScale: 1.2).foregroundStyle(Theme.ink)
                .lineLimit(1).minimumScaleFactor(0.75).padding(.leading, 18)
            Spacer(minLength: 0)
            if current.isHostedByMe {
                Button("Questions") {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { proxy.scrollTo("questions", anchor: .top) }
                }.buttonStyle(EventAttendButtonStyle())
            } else if current.isRegistered {
                Button { showConfirmation = true } label: { Label("Going", systemImage: "checkmark") }
                    .buttonStyle(EventAttendButtonStyle())
            } else {
                NavigationLink {
                    RegistrationView(event: current).toolbarVisibility(.visible, for: .navigationBar)
                } label: { Text("Register") }
                .buttonStyle(EventAttendButtonStyle())
            }
        }
        .padding(6)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.ink.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 5)
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 8)
    }

    func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }
}
