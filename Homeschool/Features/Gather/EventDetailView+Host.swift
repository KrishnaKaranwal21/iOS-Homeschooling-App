import SwiftUI

/// What the host sees: the host panel and the questions waiting for an answer.
extension EventDetailView {
    // MARK: Host view

    func hostPanel(_ proxy: ScrollViewProxy) -> some View {
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
    var hostQuestionsSection: some View {
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
