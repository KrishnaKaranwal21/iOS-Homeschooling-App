import SwiftUI

private enum EventReportReason: String, CaseIterable, Identifiable, Codable {
    case inaccurate = "Incorrect or misleading details"
    case spam = "Spam or promotion"
    case inappropriate = "Inappropriate content"
    case safety = "Safety concern"
    case other = "Something else"
    var id: String { rawValue }
}

/// Local reports can be handed to a reporting service when the event catalog is connected.
private struct EventReport: Codable {
    var id = UUID()
    let eventKey: String
    let eventTitle: String
    let reason: EventReportReason
    let details: String
    let createdAt: Date
}

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
