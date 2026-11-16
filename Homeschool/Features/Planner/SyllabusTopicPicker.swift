import SwiftUI

/// A searchable list of one subject's chapters and topics, used when adding a task from the syllabus.
struct SyllabusTopicPicker: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let subject: SyllabusSubject
    let childID: Child.ID
    let selectedID: String?
    let onSelect: (SyllabusTopic) -> Void
    @State private var query = ""

    private var progress: SyllabusProgress { SyllabusProgress(plans: state.learningPlans(for: childID)) }
    private func topics(in chapter: SyllabusChapter) -> [SyllabusTopic] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? chapter.topics : chapter.topics.filter { $0.title.localizedCaseInsensitiveContains(text) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(subject.chapters.filter { !topics(in: $0).isEmpty }) { chapter in
                    Section {
                        ForEach(topics(in: chapter)) { topic in
                            Button { onSelect(topic) } label: { row(topic) }
                        }
                    } header: {
                        Text("\(chapter.kind == "competency" ? "Area" : "Chapter") \(chapter.number) · \(chapter.title)\(chapter.isOptional == true ? " (optional)" : "")")
                            .textCase(nil)
                    }
                }
            }
            .searchable(text: $query, prompt: "Search topics")
            .overlay {
                if !query.isEmpty, !subject.chapters.contains(where: { !topics(in: $0).isEmpty }) {
                    ContentUnavailableView.search(text: query)
                }
            }
            .navigationTitle(subject.name).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private func row(_ topic: SyllabusTopic) -> some View {
        let status = progress.status(of: topic, subject: subject)
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(topic.title).foregroundStyle(Theme.ink).multilineTextAlignment(.leading)
                if status != .notStarted {
                    Text(status.rawValue).font(.caption)
                        .foregroundStyle(status == .completed ? Color(hex: 0x386553) : Theme.accent)
                }
            }
            Spacer(minLength: 0)
            if topic.id == selectedID {
                Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(Theme.accent)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(topic.id == selectedID ? .isSelected : [])
    }
}
