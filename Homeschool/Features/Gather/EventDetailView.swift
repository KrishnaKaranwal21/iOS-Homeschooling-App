import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showConfirmation = false
    @State private var showContactHost = false
    @State private var showCalendar = false
    @State private var calendarSaved = false
    @State private var showOrganizerBanner = true
    @State private var expandedAbout = false
    @State private var expandedFAQs = false
    @State private var descriptionFullHeight: CGFloat = 0
    @State private var descriptionPreviewHeight: CGFloat = 0
    @State private var showReport = false
    @State private var reportSaved = false
    @State private var reportNoticePending = false
    @State private var showDetails = false
    @State private var expandedQuestions = false
    @State private var showHost = false
    @State private var showProfile = false
    @State private var showProfilePrompt = false
    @State private var openProfileAfterPrompt = false

    private var current: Event { state.events.first { $0.id == event.id } ?? event }
    private var myQuestions: [EventQuestion] { current.questions.filter(\.askedByMe) }

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
                    reportButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 30)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background.ignoresSafeArea())
            .safeAreaInset(edge: .top, spacing: 0) { fixedHeader }
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

    private var fixedHeader: some View {
        ZStack {
            Text("Event").scaledFont(17, weight: .bold, maxScale: 1.2)
                .foregroundStyle(Theme.ink).accessibilityAddTraits(.isHeader)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").font(.system(size: 21, weight: .light))
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
                .font(.system(size: 20, weight: .light))
                .gatherGlass(in: Capsule())
            }
            .foregroundStyle(Theme.ink).buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 12)
    }

    private var organizerBanner: some View {
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
                    .foregroundStyle(Color.adaptive(0xFFFFFF, 0x151517))
                    .padding(.horizontal, 18).frame(minHeight: 34)
                    .background(Color.adaptive(0x7561D2, 0xF2F2F5), in: Capsule())
            }.buttonStyle(.plain)
        }
        .padding(16).frame(minHeight: 76)
        .background(LinearGradient(colors: [Theme.lilac, Theme.lavender.opacity(0.5)], startPoint: .leading, endPoint: .trailing), in: .rect(cornerRadius: 24))
        .overlay(alignment: .topTrailing) {
            Button { showOrganizerBanner = false } label: {
                Image(systemName: "xmark").font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.ink).frame(width: 28, height: 28)
                    .background(Theme.field, in: Circle())
            }.buttonStyle(.plain).offset(x: 6, y: -6)
                .accessibilityLabel("Dismiss organizer suggestion")
        }
    }

    private var eventSummary: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(current.title).scaledFont(32, weight: .bold, maxScale: 1.3)
                .tracking(-0.9).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 14) {
                Image(systemName: "calendar").font(.system(size: 25, weight: .regular))
                    .foregroundStyle(Color.adaptive(0xB8497B, 0xEE8BB4)).frame(width: 28)
                VStack(alignment: .leading, spacing: 6) {
                    Text(current.fullDateText).scaledFont(14, weight: .medium, maxScale: 1.35).foregroundStyle(Theme.ink)
                    HStack(spacing: 4) {
                        Text(current.timeRangeWithZone).scaledFont(13, maxScale: 1.35).foregroundStyle(Theme.secondary)
                        Button { showDetails = true } label: {
                            Image(systemName: "info.circle").font(.system(size: 12)).foregroundStyle(Theme.secondary)
                                .frame(width: 28, height: 28)
                        }.buttonStyle(.plain).accessibilityLabel("Age guidance and parent requirements")
                    }
                }
                Spacer(minLength: 0)
                Button { showCalendar = true } label: {
                    Image(systemName: calendarSaved ? "calendar.badge.checkmark" : "calendar.badge.plus").font(.system(size: 20)).foregroundStyle(Theme.ink)
                        .frame(width: 44, height: 44)
                }.buttonStyle(.plain).accessibilityLabel(calendarSaved ? "Event added to calendar. Add another copy" : "Add event to calendar")
            }
            Divider().overlay(Theme.cardBorder)
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: current.mode == .online ? "video.fill" : "mappin.and.ellipse")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color.adaptive(0x27846A, 0x76D4B8)).frame(width: 28)
                VStack(alignment: .leading, spacing: 5) {
                    Text(current.mode == .online ? "Online event" : current.locationLines.title)
                        .scaledFont(14, weight: .medium, maxScale: 1.35).foregroundStyle(Theme.ink)
                    Text(current.mode == .online ? "The host shares joining details with attendees" : current.addressDetailText)
                        .scaledFont(13, maxScale: 1.35).foregroundStyle(Theme.secondary)
                }
            }
        }
    }

    private var organizerCard: some View {
        Button { if !current.isHostedByMe { showContactHost = true } } label: {
            HStack(spacing: 16) {
                Text(initials(current.host))
                    .scaledFont(20, weight: .bold, maxScale: 1.2).foregroundStyle(Theme.ink)
                    .frame(width: 52, height: 52).background(Theme.lavender, in: .rect(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 5) {
                    Text(current.host).scaledFont(16, weight: .bold, maxScale: 1.3).foregroundStyle(Theme.ink)
                    Text(current.isHostedByMe ? "You’re organizing this event" : current.hostRole)
                        .scaledFont(13, maxScale: 1.3).foregroundStyle(Theme.secondary)
                }
                Spacer(minLength: 0)
                if !current.isHostedByMe {
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.secondary)
                }
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.field, in: .rect(cornerRadius: 26))
        }
        .buttonStyle(.plain).disabled(current.isHostedByMe)
        .accessibilityLabel(current.isHostedByMe ? "You are hosting this event" : "Contact organizer, \(current.host)")
    }

    private var descriptionText: some View {
        let content = (try? AttributedString(markdown: current.about,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(current.about)
        return Text(content).scaledFont(16, maxScale: 1.35)
            .foregroundStyle(Theme.secondary).lineSpacing(5)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            descriptionText
                .lineLimit(expandedAbout ? nil : 6)
                .fixedSize(horizontal: false, vertical: true)
                .background(alignment: .topLeading) {
                    descriptionText.lineLimit(nil).fixedSize(horizontal: false, vertical: true)
                        .hidden().accessibilityHidden(true)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { descriptionFullHeight = $0 }
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                    if !expandedAbout { descriptionPreviewHeight = $0 }
                }
            if expandedAbout || descriptionFullHeight > descriptionPreviewHeight + 1 {
                Button(expandedAbout ? "Read less" : "Read more") {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { expandedAbout.toggle() }
                }
                .scaledFont(16, weight: .semibold, maxScale: 1.3)
                .foregroundStyle(Theme.accent).buttonStyle(.plain)
                .accessibilityIdentifier("event.readMore")
            }
            Text(current.category).scaledFont(13, weight: .semibold, maxScale: 1.25)
                .foregroundStyle(Theme.ink).padding(.horizontal, 14).padding(.vertical, 7)
                .roundedStroke(Theme.cardBorder, cornerRadius: 18)
        }
    }

    private var reportButton: some View {
        Button { showReport = true } label: {
            Label("Report this event", systemImage: "flag")
                .scaledFont(17, weight: .semibold, maxScale: 1.35)
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain).padding(.top, 12).padding(.bottom, 90)
        .accessibilityIdentifier("event.report")
    }

    private var detailsSheet: some View {
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

    private var practicalDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(current.ages, systemImage: "person.2").foregroundStyle(Theme.ink)
            Label(current.parentPresence.shortTitle, systemImage: current.parentPresence.symbol).foregroundStyle(Theme.ink)
            Text(current.parentPresence.detail).foregroundStyle(Theme.secondary)
        }
        .scaledFont(13, maxScale: 1.35)
        .padding(.top, 6)
    }

    private func attendanceBar(_ proxy: ScrollViewProxy) -> some View {
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

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }
    // MARK: FAQs

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: expandedFAQs ? 10 : 0) {
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { expandedFAQs.toggle() }
            } label: {
                HStack {
                    Text(current.isHostedByMe ? "FAQs families see" : "FAQs").sectionTitle()
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.secondary)
                        .rotationEffect(.degrees(expandedFAQs ? 180 : 0))
                }
                .frame(minHeight: 48).padding(.horizontal, 6).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(expandedFAQs ? "Expanded" : "Collapsed")
            .accessibilityHint("Show or hide the event questions")
            .accessibilityIdentifier("event.faqToggle")

            if expandedFAQs {
                VStack(spacing: 0) {
                    let faqs = current.allFAQs
                    ForEach(Array(faqs.enumerated()), id: \.element.id) { index, faq in
                        DisclosureGroup {
                            Text(faq.answer).rowDetail()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 12)
                        } label: {
                            Text(faq.question).rowTitle().multilineTextAlignment(.leading)
                                .padding(.vertical, 12)
                        }
                        .tint(Theme.secondary)
                        if index < faqs.count - 1 {
                            Rectangle().fill(Theme.ink.opacity(0.06)).frame(height: 1)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .background(Theme.surface, in: .rect(cornerRadius: 24))
                .roundedStroke(Theme.lilacBorder, cornerRadius: 24, lineWidth: 1)
                .transition(.opacity)
            }
        }
    }

    /// The questions I asked this host and their answers, so I can check back here.
    private var myQuestionsSection: some View {
        let mine = current.questions.filter(\.askedByMe).sorted { $0.date > $1.date }
        return VStack(alignment: .leading, spacing: 10) {
            Text("Your questions")
                .sectionTitle()
                .padding(.horizontal, 6)

            if mine.isEmpty {
                Text("Questions you ask the host, and their answers, show up here.")
                    .rowDetail()
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface, in: .rect(cornerRadius: 24))
                    .roundedStroke(Theme.lilacBorder, cornerRadius: 24, lineWidth: 1)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(mine.enumerated()), id: \.element.id) { index, question in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "bubble.left.fill")
                                    .foregroundStyle(Theme.tabSelected)
                                    .padding(.top, 3)
                                Text(question.text)
                                    .rowTitle()
                                    .multilineTextAlignment(.leading)
                            }
                            if let answer = question.answer {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Answer from \(current.host)")
                                        .scaledFont(13, weight: .semibold, maxScale: 1.25)
                                        .foregroundStyle(Theme.tabSelected)
                                    Text(answer)
                                        .rowDetail()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Theme.lilac, in: .rect(cornerRadius: 16))
                            } else {
                                Label("Waiting for \(current.host) to reply", systemImage: "clock")
                                    .scaledFont(13, maxScale: 1.3)
                                    .foregroundStyle(Theme.gatherText)
                            }
                        }
                        .padding(.vertical, 14)
                        if index < mine.count - 1 {
                            Rectangle().fill(Theme.ink.opacity(0.06)).frame(height: 1)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .background(Theme.surface, in: .rect(cornerRadius: 24))
                .roundedStroke(Theme.lilacBorder, cornerRadius: 24, lineWidth: 1)
            }

            Button { showContactHost = true } label: {
                Label("Ask the host", systemImage: "bubble.left.and.text.bubble.right")
                    .scaledFont(15, weight: .semibold, maxScale: 1.2)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                    .background(Capsule().fill(Theme.lavender))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 6)
        }
    }

    // MARK: Host view

    private func hostPanel(_ proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "star.fill")
                .scaledFont(17, maxScale: 1.2)
                .foregroundStyle(Theme.ink)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Theme.surface.opacity(0.8)))

            VStack(alignment: .leading, spacing: 2) {
                Text("You’re hosting this event")
                    .rowTitle()
                Text(current.registeredCount == 1
                     ? "1 family registered"
                     : "\(current.registeredCount) families registered")
                    .rowDetail()
            }
            Spacer(minLength: 8)
            if current.unansweredCount > 0 {
                Button { withAnimation { proxy.scrollTo("questions", anchor: .top) } } label: {
                    Text("\(current.unansweredCount) new")
                        .scaledFont(14, weight: .semibold, maxScale: 1.2)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .background(Capsule().fill(Theme.buttonFill))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(current.unansweredCount) new questions. Show questions")
            }
        }
        .padding(14)
        .background(Theme.pink.opacity(0.65), in: .rect(cornerRadius: 24))
    }

    /// Questions families sent. The host answers here and can add the answer to the public FAQs.
    private var hostQuestionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Questions from families")
                    .sectionTitle()
                if current.unansweredCount > 0 {
                    Text("\(current.unansweredCount) waiting")
                        .scaledFont(13, weight: .semibold, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Theme.pink))
                }
            }
            .padding(.horizontal, 6)

            if current.questions.isEmpty {
                Text("No questions yet. When a family asks something, it shows up here and on your Gather page.")
                    .rowDetail()
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface, in: .rect(cornerRadius: 24))
                    .roundedStroke(Theme.lilacBorder, cornerRadius: 24, lineWidth: 1)
            } else {
                VStack(spacing: 0) {
                    let items = current.sortedQuestions
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, question in
                        HostQuestionRow(question: question) { answer, publish in
                            state.answerQuestion(question.id, on: current.id, answer: answer, publish: publish)
                        }
                        if index < items.count - 1 {
                            Rectangle().fill(Theme.ink.opacity(0.06)).frame(height: 1)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .background(Theme.surface, in: .rect(cornerRadius: 24))
                .roundedStroke(Theme.lilacBorder, cornerRadius: 24, lineWidth: 1)
            }
        }
    }


}

/// One family question in the host's inbox: shows the question, and lets the host answer it.
private struct HostQuestionRow: View {
    let question: EventQuestion
    let onAnswer: (_ answer: String, _ addToFAQs: Bool) -> Void

    @State private var answer = ""
    @State private var addToFAQs = true

    private var canSend: Bool { !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: question.isAnswered ? "checkmark.circle.fill" : "questionmark.bubble.fill")
                    .foregroundStyle(question.isAnswered ? Theme.tabSelected : Color(hex: 0xE5737A))
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(question.text)
                        .rowTitle()
                        .multilineTextAlignment(.leading)
                    Text("\(question.asker) · \(question.date.formatted(.relative(presentation: .named)))")
                        .rowDetail()
                }
            }

            if let reply = question.answer {
                Text(reply)
                    .rowDetail()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Theme.lilac, in: .rect(cornerRadius: 16))
            } else {
                TextField("Write your answer", text: $answer, axis: .vertical)
                    .lineLimit(2...5)
                    .scaledFont(16, maxScale: 1.3)
                    .gatherField()

                Toggle("Add to this event’s FAQs", isOn: $addToFAQs)
                    .scaledFont(15, maxScale: 1.3)
                    .tint(Theme.tabSelected)

                Button("Send answer") {
                    guard canSend else { return }
                    onAnswer(answer, addToFAQs)
                }
                .buttonStyle(.primaryHomeschool(isDimmed: !canSend))
            }
        }
        .padding(.vertical, 14)
    }
}

private struct EventAttendButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaledFont(17, weight: .semibold, maxScale: 1.25)
            .foregroundStyle(Color.adaptive(0xFFFFFF, 0x121214))
            .frame(minWidth: 100, minHeight: 46).padding(.horizontal, 16)
            .background(LinearGradient(colors: [Color.adaptive(0x2A2A2D, 0xFFFFFF), Color.adaptive(0x1B1D1C, 0xDCDCE1)], startPoint: .top, endPoint: .bottom), in: Capsule())
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
