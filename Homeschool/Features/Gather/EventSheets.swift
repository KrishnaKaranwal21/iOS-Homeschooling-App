import SwiftUI

// MARK: - ContactHostSheet

/// Ask the host a question. The question and the answer are kept on the event page, not in Chats.
struct ContactHostSheet: View {
    let event: Event

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var message = ""
    @FocusState private var focused: Bool

    private let suggestions = [
        "What should we bring?",
        "Can my younger child join?",
        "Is there parking nearby?",
        "Is there a waiting list?"
    ]

    private var canSend: Bool { !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Text(String(event.host.prefix(1)).uppercased())
                            .scaledFont(18, weight: .bold, maxScale: 1.15)
                            .foregroundStyle(Theme.ink)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(Theme.lavender))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.host).rowTitle()
                            Text("About “\(event.title)”").rowDetail().lineLimit(1)
                        }
                    }

                    Text("Quick questions").sectionTitle()

                    FlowLayout(spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button { message = suggestion } label: {
                                Text(suggestion)
                                    .scaledFont(14, weight: .medium, maxScale: 1.2)
                                    .foregroundStyle(Theme.ink)
                                    .padding(.horizontal, 14)
                                    .frame(height: 34)
                                    .background(Capsule().fill(Theme.field))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Your message").sectionTitle().padding(.top, 4)

                    TextField("Write your question", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                        .scaledFont(17, maxScale: 1.3)
                        .focused($focused)
                        .gatherField()

                    Text("Your question and the host’s answer show on this event’s page. We’ll let you know when they reply.")
                        .caption()

                    Button("Send question") {
                        guard canSend else { return }
                        send()
                    }
                    .buttonStyle(.primaryHomeschool(isDimmed: !canSend))
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background)
            .navigationTitle("Ask the host")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
        .presentationDetents([.large])
    }

    private func send() {
        state.askHost(of: event.id, text: message)
        dismiss()
    }
}

// MARK: - CompleteProfileSheet

/// Shown when someone tries to host with an unfinished profile.
struct CompleteProfileSheet: View {
    let missing: [String]
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .scaledFont(40)
                .foregroundStyle(Theme.tabSelected)
                .padding(.top, 8)

            Text("Complete your profile to host")
                .detailTitle()

            Text("Families see who is hosting, so we need a few details first.")
                .pageSubtitle()

            VStack(alignment: .leading, spacing: 10) {
                ForEach(missing, id: \.self) { item in
                    Label(item, systemImage: "circle")
                        .rowTitle()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: .rect(cornerRadius: 20))

            Spacer(minLength: 0)

            Button("Complete profile", action: onComplete)
                .buttonStyle(.primaryHomeschool)
            Button("Not now") { dismiss() }
                .scaledFont(16, weight: .medium, maxScale: 1.2)
                .foregroundStyle(Theme.secondary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
        }
        .padding(24)
        .background(Theme.background)
        .presentationDetents([.medium, .large])
    }
}

// MARK: - EventReportReason

enum EventReportReason: String, CaseIterable, Identifiable, Codable {
    case inaccurate = "Incorrect or misleading details"
    case spam = "Spam or promotion"
    case inappropriate = "Inappropriate content"
    case safety = "Safety concern"
    case other = "Something else"
    var id: String { rawValue }
}

// MARK: - EventReport

/// Local reports can be handed to a reporting service when the event catalog is connected.
struct EventReport: Codable {
    var id = UUID()
    let eventKey: String
    let eventTitle: String
    let reason: EventReportReason
    let details: String
    let createdAt: Date
}

// MARK: - ReportEventSheet

struct ReportEventSheet: View {
    let event: Event
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("gather.eventReports") private var storedReports = Data()
    @State private var reason: EventReportReason?
    @State private var details = ""
    @State private var saveError = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(event.title).font(.headline).foregroundStyle(Theme.ink)
                    Text("Tell us what’s wrong with this event.")
                        .font(.subheadline).foregroundStyle(Theme.secondary)
                }
                Section("Reason") {
                    ForEach(EventReportReason.allCases) { option in
                        Button { reason = option } label: {
                            HStack(spacing: 14) {
                                Text(option.rawValue).foregroundStyle(Theme.ink)
                                Spacer(minLength: 4)
                                Image(systemName: reason == option ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(reason == option ? Theme.accent : Theme.checkBorder)
                            }.frame(minHeight: 30).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(reason == option ? .isSelected : [])
                    }
                }
                Section {
                    TextField("Add details (optional)", text: $details, axis: .vertical)
                        .lineLimit(4...8)
                } header: { Text("More information") } footer: {
                    Text("Reports are currently saved on this device. They aren’t sent to an organizer or moderation team.")
                }
                Section {
                    Button("Save report", action: saveReport)
                        .font(.headline).frame(maxWidth: .infinity, minHeight: 36)
                        .disabled(reason == nil)
                }
            }
            .tint(Theme.accent)
            .navigationTitle("Report this event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .alert("Couldn’t save report", isPresented: $saveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your existing reports are unchanged. Please try again.")
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func saveReport() {
        guard let reason else { return }
        do {
            var reports = storedReports.isEmpty ? [] : try JSONDecoder().decode([EventReport].self, from: storedReports)
            reports.append(EventReport(eventKey: event.storageKey, eventTitle: event.title,
                reason: reason, details: details.trimmingCharacters(in: .whitespacesAndNewlines), createdAt: .now))
            storedReports = try JSONEncoder().encode(reports)
            onSaved()
        } catch { saveError = true }
    }
}
