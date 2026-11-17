import SwiftUI

/// FAQs and the questions the person has asked the host.
extension EventDetailView {
    // MARK: FAQs

    var faqSection: some View {
        VStack(alignment: .leading, spacing: expandedFAQs ? 10 : 0) {
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { expandedFAQs.toggle() }
            } label: {
                HStack {
                    Text(current.isHostedByMe ? "FAQs families see" : "FAQs").sectionTitle()
                    Spacer()
                    Image(systemName: "chevron.down").accessibilityHidden(true)
                        .scaledFont(14, weight: .semibold).foregroundStyle(Theme.secondary)
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
                    if !current.isHostedByMe {
                        Rectangle().fill(Theme.ink.opacity(0.06)).frame(height: 1)
                        Button { showContactHost = true } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "bubble.left.and.text.bubble.right")
                                    .foregroundStyle(Theme.accent)
                                Text("Ask the host a question").rowTitle()
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right").accessibilityHidden(true)
                                    .scaledFont(12, weight: .semibold).foregroundStyle(Theme.secondary)
                            }
                            .padding(.vertical, 14).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("event.askHost")
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
    var myQuestionsSection: some View {
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
}
