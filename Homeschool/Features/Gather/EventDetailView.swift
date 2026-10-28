import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Environment(AppState.self) private var state
    @State private var showConfirmation = false
    @State private var showContactHost = false

    /// Latest copy from the app state, so the Register button reflects a new registration.
    private var current: Event {
        state.events.first { $0.id == event.id } ?? event
    }

    var body: some View {
        ScrollViewReader { proxy in
            content(proxy)
        }
    }

    private func content(_ proxy: ScrollViewProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                cover
                titleRow
                    .padding(.top, -14)
                infoCard
                if current.isHostedByMe { hostPanel(proxy) } else { hostCard }
                Text(current.about)
                    .bodyText()
                    .lineSpacing(3)
                    .padding(.horizontal, 6)
                if current.isHostedByMe { hostQuestionsSection.id("questions") }
                faqSection
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
                        .foregroundStyle(Theme.ink)
                }
                // A tinted circle from the system, so there is no second white ring around the button.
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(Theme.lavender)
                .sensoryFeedback(.selection, trigger: state.isBookmarked(current))
                .accessibilityLabel(state.isBookmarked(current) ? "Remove from saved events" : "Save event")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if current.isHostedByMe { hostBottomBar(proxy) } else { bottomBar }
        }
        .sheet(isPresented: $showConfirmation) { GatherConfirmationSheet(event: current) }
        .sheet(isPresented: $showContactHost) { ContactHostSheet(event: current) }
    }

    // MARK: Pieces

    private var cover: some View {
        EventCover(event: current)
            .frame(height: 240)
            .clipShape(GatherWaveShape())
            .overlay(alignment: .topLeading) {
                Label(current.kind.rawValue, systemImage: "person.2.fill")
                    .scaledFont(14, weight: .medium, maxScale: 1.2)
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
                    .detailTitle()
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text("\(current.mode.rawValue) · \(current.ages)")
                    .rowDetail()
            }
            .padding(.top, 14)
        }
    }

    private var dateTile: some View {
        VStack(spacing: 0) {
            Text(current.month)
                .scaledFont(13, weight: .semibold, maxScale: 1.2)
                .foregroundStyle(Color(hex: 0xE5737A))
            Text(current.day.formatted(.number.precision(.integerLength(2...))))
                .scaledFont(30, weight: .heavy, maxScale: 1.2)
                .foregroundStyle(Theme.ink)
            Text(current.weekday)
                .scaledFont(13, maxScale: 1.2)
                .foregroundStyle(Theme.secondary)
        }
        .frame(width: 72, height: 82)
        .background(Color.white, in: .rect(cornerRadius: 22))
        .roundedStroke(Theme.lilacBorder, cornerRadius: 26, lineWidth: 1)
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
        .background(Theme.lilac, in: .rect(cornerRadius: 24))
    }

    private func infoRow(icon: String, title: String, detail: String?, showsChevron: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .scaledFont(16, maxScale: 1.2)
                .foregroundStyle(Theme.gatherText)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color.white))
                .overlay(Circle().stroke(Theme.lilacBorder, lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .rowTitle()
                if let detail {
                    Text(detail)
                        .rowDetail()
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
                .scaledFont(17, maxScale: 1.2)
                .foregroundStyle(Theme.gatherText)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color.white.opacity(0.8)))

            VStack(alignment: .leading, spacing: 2) {
                Text("Hosted by \(current.host)")
                    .rowTitle()
                Text(current.hostRole)
                    .rowDetail()
            }
            Spacer(minLength: 8)
            Button { showContactHost = true } label: {
                Label("Message", systemImage: "bubble.left")
                    .scaledFont(14, weight: .semibold, maxScale: 1.2)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(Capsule().fill(Color.white))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Message the host")
        }
        .padding(14)
        .background(Theme.pink.opacity(0.65), in: .rect(cornerRadius: 24))
    }

    // MARK: FAQs

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(current.isHostedByMe ? "FAQs families see" : "FAQs")
                .sectionTitle()
                .padding(.horizontal, 6)

            VStack(spacing: 0) {
                let faqs = current.allFAQs
                ForEach(Array(faqs.enumerated()), id: \.element.id) { index, faq in
                    DisclosureGroup {
                        Text(faq.answer)
                            .rowDetail()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 12)
                    } label: {
                        Text(faq.question)
                            .rowTitle()
                            .multilineTextAlignment(.leading)
                            .padding(.vertical, 12)
                    }
                    .tint(Theme.secondary)
                    if index < faqs.count - 1 {
                        Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(Color.white, in: .rect(cornerRadius: 24))
            .roundedStroke(Theme.lilacBorder, cornerRadius: 24, lineWidth: 1)

            if !current.isHostedByMe {
                Button { showContactHost = true } label: {
                    Label("Still have a question? Message the host", systemImage: "bubble.left.and.text.bubble.right")
                        .scaledFont(15, weight: .semibold, maxScale: 1.2)
                        .foregroundStyle(Theme.tabSelected)
                        .padding(.horizontal, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Host view

    private func hostPanel(_ proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "star.fill")
                .scaledFont(17, maxScale: 1.2)
                .foregroundStyle(Theme.ink)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color.white.opacity(0.8)))

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
                        .background(Capsule().fill(Theme.ink))
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
                    .background(Color.white, in: .rect(cornerRadius: 24))
                    .roundedStroke(Theme.lilacBorder, cornerRadius: 24, lineWidth: 1)
            } else {
                VStack(spacing: 0) {
                    let items = current.sortedQuestions
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, question in
                        HostQuestionRow(question: question) { answer, publish in
                            state.answerQuestion(question.id, on: current.id, answer: answer, publish: publish)
                        }
                        if index < items.count - 1 {
                            Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .background(Color.white, in: .rect(cornerRadius: 24))
                .roundedStroke(Theme.lilacBorder, cornerRadius: 24, lineWidth: 1)
            }
        }
    }

    private func hostBottomBar(_ proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hosting")
                    .scaledFont(22, weight: .bold, maxScale: 1.2)
                    .foregroundStyle(Theme.ink)
                Text("\(current.registeredCount) registered · \(current.priceText)")
                    .scaledFont(13, maxScale: 1.25)
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .layoutPriority(-1)
            Spacer(minLength: 8)

            Button { withAnimation { proxy.scrollTo("questions", anchor: .top) } } label: {
                Label(current.unansweredCount > 0 ? "Answer \(current.unansweredCount)" : "Questions",
                      systemImage: "bubble.left.and.text.bubble.right")
                    .scaledFont(16, weight: .semibold, maxScale: 1.2)
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 20)
                    .frame(minHeight: 52)
                    .gatherGlass(in: Capsule(), tint: Theme.ink)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background {
            Color.white
                .clipShape(.rect(cornerRadius: 32))
                .shadow(color: .black.opacity(0.08), radius: 16, y: 4)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    private var bottomBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(current.priceText)
                    .scaledFont(22, weight: .bold, maxScale: 1.2)
                    .foregroundStyle(Theme.ink)
                Text(priceCaption)
                    .scaledFont(13, maxScale: 1.25)
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .layoutPriority(-1)
            Spacer(minLength: 8)

            if current.isRegistered {
                Button { showConfirmation = true } label: {
                    Label("Registered", systemImage: "checkmark.circle.fill")
                        .scaledFont(16, weight: .semibold, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 20)
                        .frame(minHeight: 52)
                        .gatherGlass(in: Capsule(), tint: Theme.lilac)
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink { RegistrationView(event: current) } label: {
                    Text("Register")
                        .scaledFont(16, weight: .semibold, maxScale: 1.2)
                        .foregroundStyle(Color.white)
                        .frame(width: 150)
                        .frame(minHeight: 52)
                        .gatherGlass(in: Capsule(), tint: Theme.ink)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background {
            Color.white
                .clipShape(.rect(cornerRadius: 32))
                .shadow(color: .black.opacity(0.08), radius: 16, y: 4)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    private var priceCaption: String {
        guard current.isRegistered else { return current.kind.rawValue }
        return state.canCancel(current) ? "Cancel any time" : "Paid"
    }

    private var mapsURL: URL {
        let query = current.location.replacingOccurrences(of: "\n", with: ", ")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://maps.apple.com/?q=\(query)") ?? URL(string: "https://maps.apple.com")!
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
