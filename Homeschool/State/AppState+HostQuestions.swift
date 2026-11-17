import SwiftUI

/// Questions between families and event hosts (simulated locally in this prototype).
extension AppState {
    /// A parent asks an event's host a question. It is kept on the event page, not in Chats.
    func askHost(of eventID: Event.ID, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = events.firstIndex(where: { $0.id == eventID }) else { return }
        let question = EventQuestion(asker: account?.name ?? "You", text: trimmed, date: .now, askedByMe: true)
        events[index].questions.append(question)
        // Schedules a canned reply for demonstration because the prototype has no host-messaging backend.
        simulateHostAnswer(eventID: eventID, questionID: question.id)
    }

    /// A family asks the signed-in host a question. Shows a pop-up and a notification.
    func receiveQuestion(eventID: Event.ID, from asker: String, text: String) {
        guard let index = events.firstIndex(where: { $0.id == eventID }) else { return }
        events[index].questions.append(EventQuestion(asker: asker, text: text, date: .now))
        let title = events[index].title
        addNotification(AppNotification(symbol: "bubble.left.and.text.bubble.right",
                                        title: "New question on \(title)", detail: "\(asker): “\(text)”",
                                        time: "Just now", isNew: true, action: .openEventQuestions(eventID)))
        // Only the main app shows pop-ups and schedules reminders, not onboarding, login or setup.
        guard stage == .main, preferences.notifyGatherings else { return }
        popup = AppPopup(title: "A new question", headline: "\(asker) asked about “\(title)”",
                         detail: "\(events[index].unansweredCount) waiting for your answer",
                         message: "Families like quick replies. Answer when you have a moment.",
                         buttonTitle: "View question", action: .openEventQuestions(eventID))
    }

    /// The host's answer to a question I asked. Shows a pop-up and a notification.
    func receiveAnswer(eventID: Event.ID, questionID: EventQuestion.ID, answer: String) {
        guard let e = events.firstIndex(where: { $0.id == eventID }),
              let q = events[e].questions.firstIndex(where: { $0.id == questionID }) else { return }
        events[e].questions[q].answer = answer
        let title = events[e].title
        let host = events[e].host
        addNotification(AppNotification(symbol: "checkmark.bubble", title: "\(host) answered your question",
                                        detail: "About “\(title)”", time: "Just now", isNew: true,
                                        action: .openEventQuestions(eventID)))
        // Only the main app shows pop-ups and schedules reminders, not onboarding, login or setup.
        guard stage == .main, preferences.notifyGatherings else { return }
        popup = AppPopup(title: "You got an answer", headline: "\(host) replied",
                         detail: "About “\(title)”",
                         message: "See the answer on the event page.",
                         buttonTitle: "View answer", action: .openEventQuestions(eventID))
    }

    /// PROTOTYPE ONLY: there is no server yet, so a host's answer and a family's question are made up here a few
    /// seconds after the real action. Replace these with the real updates when the server exists.
    func simulateHostAnswer(eventID: Event.ID, questionID: EventQuestion.ID) {
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            self?.receiveAnswer(eventID: eventID, questionID: questionID,
                                answer: "Thanks for asking! Yes, that works. Message us here if you need anything else.")
        }
    }

    /// Waits asynchronously before creating a random prototype family question for a hosted event.
    func simulateIncomingQuestion(for eventID: Event.ID) {
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(15))
            guard let self else { return }
            let asker = MockData.parents.randomElement()?.firstName ?? "A parent"
            self.receiveQuestion(eventID: eventID, from: asker, text: self.incomingQuestionTexts.randomElement() ?? "Is this open to everyone?")
        }
    }

    /// The host answers a family's question. With `publish`, it also joins the event's public FAQs.
    func answerQuestion(_ questionID: EventQuestion.ID, on eventID: Event.ID, answer: String, publish: Bool) {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let e = events.firstIndex(where: { $0.id == eventID }),
              let q = events[e].questions.firstIndex(where: { $0.id == questionID }) else { return }
        events[e].questions[q].answer = trimmed
        if publish {
            events[e].faqs.append(EventFAQ(question: events[e].questions[q].text, answer: trimmed))
        }
    }

    /// Events I host that still have questions waiting for an answer.
    var hostedEventsWithQuestions: [Event] {
        events.filter { $0.isHostedByMe && $0.unansweredCount > 0 }
    }
}
