import SwiftUI

struct WeekTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var state
    let week: WeeklyPlan
    let isEditing: Bool
    private let originalActivity: WeekActivity
    let onSave: (WeekActivity) -> Void
    @State private var activity: WeekActivity
    @State private var hasTime: Bool
    @State private var chosenTime: Date
    @State private var reminderUnavailable = false
    @State private var showDate = false
    @State private var showTime = false
    @State private var showSteps = false
    @State private var showNotes = false
    @State private var durationEditor: DurationField?
    @State private var source: TaskSource?
    @State private var showTopicPicker = false
    @State private var manualDraft = ""

    /// Where a new task's topic comes from: the child's NIOS syllabus, or typed in by the parent.
    private enum TaskSource { case syllabus, manual }

    private enum DurationField: String, Identifiable {
        case learning, help
        var id: String { rawValue }
    }

    init(activity: WeekActivity, week: WeeklyPlan, isEditing: Bool, onSave: @escaping (WeekActivity) -> Void) {
        self.week = week
        self.isEditing = isEditing
        self.originalActivity = activity
        self.onSave = onSave
        _activity = State(initialValue: activity)
        _hasTime = State(initialValue: activity.time != nil)
        _chosenTime = State(initialValue: activity.time ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: activity.date)!)
        _showSteps = State(initialValue: !activity.smallSteps.isEmpty)
        _showNotes = State(initialValue: !activity.notes.isEmpty)
    }

    private var title: String { activity.title.trimmingCharacters(in: .whitespacesAndNewlines) }
    /// Only the subjects this child is studying, plus the task's own subject when an older task uses another one.
    private var childSubjects: [String] { state.child.subjectNames }
    private var subjectOptions: [String] {
        var options = childSubjects
        let current = activity.subject.trimmingCharacters(in: .whitespacesAndNewlines)
        if !current.isEmpty, (isEditing || activity.syllabusTopicID != nil), !options.contains(current) { options.append(current) }
        return options
    }

    // MARK: Syllabus choice

    private var syllabusSubjects: [SyllabusSubject] { MockData.syllabus(for: state.child).filter(\.hasOutline) }
    /// Only brand-new tasks offer the syllabus; edits and tasks already planned from a topic keep the plain form.
    private var canPickFromSyllabus: Bool {
        !isEditing && originalActivity.syllabusTopicID == nil && !syllabusSubjects.isEmpty
    }
    private var activeSource: TaskSource { source ?? (canPickFromSyllabus ? .syllabus : .manual) }
    private var syllabusSubject: SyllabusSubject? {
        let key = NIOSSyllabus.subjectKey(activity.subject)
        return syllabusSubjects.first { NIOSSyllabus.subjectKey($0.name) == key } ?? syllabusSubjects.first
    }
    private var chosenTopic: SyllabusTopic? {
        guard let id = activity.syllabusTopicID else { return nil }
        return syllabusSubject?.topics.first { $0.id == id }
    }
    private var chosenChapter: SyllabusChapter? {
        guard let chosenTopic else { return nil }
        return syllabusSubject?.chapters.first { $0.topics.contains(chosenTopic) }
    }

    private func setSource(_ newSource: TaskSource) {
        guard newSource != activeSource else { return }
        withAnimation(.snappy(duration: 0.25)) {
            if newSource == .syllabus {
                manualDraft = activity.title
                activity.title = ""
                if let subject = syllabusSubject { activity.subject = subject.name }
            } else {
                activity.syllabusTopicID = nil
                activity.title = manualDraft
            }
            source = newSource
        }
    }

    private func chooseSyllabusSubject(_ name: String) {
        guard name != activity.subject else { return }
        activity.subject = name
        activity.syllabusTopicID = nil
        activity.title = ""
    }

    private func choose(_ topic: SyllabusTopic, in subject: SyllabusSubject) {
        activity.subject = subject.name
        activity.title = topic.title
        activity.syllabusTopicID = topic.id
        showTopicPicker = false
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isEditing ? "Edit task" : "Add task").detailTitle()
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 38, height: 38)
                        .gatherGlass(in: Circle(), tint: Theme.lilac.opacity(0.35))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close task")
            }
            .padding(.horizontal, 22).padding(.top, 26).padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if canPickFromSyllabus { sourcePicker }
                    if activeSource == .syllabus { syllabusCard } else { activityCard }
                    Text("When").sectionTitle().padding(.top, 2)
                    scheduleCard
                    HStack(spacing: 10) {
                        durationCard(title: "Learning time", minutes: activity.minutes,
                                     detail: "Total activity time", field: .learning)
                        durationCard(title: "Your help", minutes: activity.helpMinutes,
                                     detail: "Part of the \(activity.minutes) min", field: .help)
                    }
                    detailsCard
                }
                .padding(.horizontal, 20).padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .foregroundStyle(Theme.ink)
        .background(Theme.background)
        .safeAreaInset(edge: .bottom, spacing: 0) { saveFooter }
        .sheet(item: $durationEditor) { field in
            durationPicker(field)
                .presentationDetents([.height(310)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTopicPicker) {
            if let subject = syllabusSubject {
                SyllabusTopicPicker(subject: subject, childID: state.child.id,
                                    selectedID: activity.syllabusTopicID) { choose($0, in: subject) }
                    .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: activity.reminder) { _, enabled in
            guard enabled else { return }
            Task { @MainActor in
                let allowed = await ExamReminders.requestAuthorization()
                reminderUnavailable = !allowed
                if !allowed { activity.reminder = false }
            }
        }
        .onChange(of: activity.minutes) { _, minutes in
            activity.helpMinutes = min(activity.helpMinutes, minutes)
        }
        .onAppear {
            // New tasks start on one of the child's own subjects instead of a generic default.
            guard !isEditing, activity.syllabusTopicID == nil, !childSubjects.isEmpty, !childSubjects.contains(activity.subject) else { return }
            let key = LearningProgress.subjectKey(activity.subject)
            activity.subject = childSubjects.first { LearningProgress.subjectKey($0) == key } ?? childSubjects[0]
        }
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACTIVITY")
                .scaledFont(11, weight: .semibold, maxScale: 1.2)
                .foregroundStyle(WeekStyle.secondary).tracking(0.5)
            // A single-line placeholder that grows as the name wraps, so the cursor sits on the same line as the hint.
            TextField(TaskIdeas.title(for: activity.subject, level: state.child.level, slot: 0), text: $activity.title, axis: .vertical)
                .scaledFont(28, weight: .bold, maxScale: 1.2)
                .lineLimit(1...4)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Activity name")
            Menu {
                Picker("Subject", selection: $activity.subject) {
                    ForEach(subjectOptions, id: \.self) { Text($0).tag($0) }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: subjectSymbol)
                    Text(activity.subject)
                    Image(systemName: "chevron.down").font(.system(size: 11))
                }
                .scaledFont(14, weight: .medium, maxScale: 1.2)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color(hex: 0xECEAF6), in: Capsule())
                .overlay(Capsule().strokeBorder(.white, lineWidth: 1))
            }
            .accessibilityLabel("Subject, \(activity.subject)")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0xEEEEEE), in: .rect(cornerRadius: 16))
    }

    private var sourcePicker: some View {
        HStack(spacing: 4) {
            sourceOption("From syllabus", symbol: "books.vertical", for: .syllabus)
            sourceOption("My own", symbol: "pencil", for: .manual)
        }
        .padding(4)
        .background(WeekStyle.field, in: Capsule())
        .padding(.bottom, 2)
    }

    private func sourceOption(_ title: String, symbol: String, for option: TaskSource) -> some View {
        let selected = activeSource == option
        return Button { setSource(option) } label: {
            Label(title, systemImage: symbol)
                .scaledFont(14, weight: .semibold, maxScale: 1.2)
                .foregroundStyle(selected ? Theme.ink : WeekStyle.secondary)
                .frame(maxWidth: .infinity).frame(height: 38)
                .background(selected ? Theme.surface : Color.clear, in: Capsule())
                .shadow(color: .black.opacity(selected ? 0.06 : 0), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var syllabusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SYLLABUS TOPIC")
                .scaledFont(11, weight: .semibold, maxScale: 1.2)
                .foregroundStyle(WeekStyle.secondary).tracking(0.5)
            Menu {
                Picker("Subject", selection: Binding(get: { syllabusSubject?.name ?? activity.subject },
                                                     set: chooseSyllabusSubject)) {
                    ForEach(syllabusSubjects) { Text($0.name).tag($0.name) }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: SubjectCardPalette.symbol(for: syllabusSubject?.name ?? activity.subject))
                    Text(syllabusSubject?.name ?? activity.subject)
                    Image(systemName: "chevron.down").font(.system(size: 11))
                }
                .scaledFont(14, weight: .medium, maxScale: 1.2)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color(hex: 0xECEAF6), in: Capsule())
                .overlay(Capsule().strokeBorder(.white, lineWidth: 1))
            }
            .accessibilityLabel("Subject, \(syllabusSubject?.name ?? activity.subject)")

            Button { showTopicPicker = true } label: {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let chosenTopic {
                            if let chapter = chosenChapter {
                                Text(chapter.title).scaledFont(12, weight: .medium, maxScale: 1.25)
                                    .foregroundStyle(WeekStyle.secondary).lineLimit(1)
                            }
                            Text(chosenTopic.title)
                                .scaledFont(24, weight: .bold, maxScale: 1.2)
                                .multilineTextAlignment(.leading)
                        } else {
                            Text("Choose a topic")
                                .scaledFont(24, weight: .bold, maxScale: 1.2)
                                .foregroundStyle(WeekStyle.secondary.opacity(0.7))
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(WeekStyle.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface, in: .rect(cornerRadius: 12))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(chosenTopic.map { "Topic, \($0.title)" } ?? "Choose a topic")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0xEEEEEE), in: .rect(cornerRadius: 16))
    }

    private var subjectSymbol: String {
        switch activity.subject.lowercased() {
        case "coding", "computer skills": return "chevron.left.forwardslash.chevron.right"
        case "maths": return "function"
        case "science": return "flask"
        case "art & craft": return "paintpalette"
        default: return "book"
        }
    }

    private var scheduleCard: some View {
        VStack(spacing: 0) {
            Button { withAnimation { showDate.toggle() } } label: {
                fieldRow("Date") { valuePill(activity.date.formatted(.dateTime.day().month(.abbreviated).year())) }
            }
            .buttonStyle(.plain)
            if showDate {
                DatePicker("Activity date", selection: $activity.date,
                           in: week.weekStart...week.weekEnd, displayedComponents: .date)
                    .datePickerStyle(.graphical).labelsHidden()
            }
            Divider().overlay(WeekStyle.border)
            Menu {
                Button("Anytime") { hasTime = false; showTime = false }
                Button("Choose a time") { hasTime = true; showTime = true }
            } label: {
                fieldRow("Time") {
                    valuePill(hasTime ? chosenTime.formatted(date: .omitted, time: .shortened) : "Anytime")
                }
            }
            if showTime && hasTime {
                DatePicker("Start time", selection: $chosenTime, displayedComponents: .hourAndMinute)
                    .padding(.vertical, 8)
            }
            Divider().overlay(WeekStyle.border)
            Menu {
                Picker("Repeat", selection: $activity.repeatRule) {
                    ForEach(ActivityRepeat.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
            } label: {
                fieldRow("Repeat") { valuePill(activity.repeatRule.rawValue) }
            }
        }
        .padding(.horizontal, 14)
        .weekFormCard()
    }

    private func durationCard(title: String, minutes: Int, detail: String, field: DurationField) -> some View {
        Button { durationEditor = field } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).scaledFont(13, weight: .medium, maxScale: 1.2).foregroundStyle(WeekStyle.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(minutes)").scaledFont(31, weight: .bold, maxScale: 1.2)
                    Text("min").scaledFont(15, weight: .medium, maxScale: 1.2)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.system(size: 12))
                }
                Text(detail).scaledFont(11, maxScale: 1.2).foregroundStyle(WeekStyle.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .background(WeekStyle.field, in: .rect(cornerRadius: 15))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(minutes) minutes")
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            Toggle("Reminder", isOn: $activity.reminder)
                .scaledFont(15, weight: .medium, maxScale: 1.2)
                .tint(WeekStyle.purple).padding(.vertical, 8)
            if reminderUnavailable {
                Text("Enable notifications in Settings to use reminders.")
                    .caption().frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 8)
            }
            if activity.reminder {
                Text("Remind me at the task’s start time.")
                    .caption().frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 8)
                if !hasTime {
                    Button("Choose a time for the reminder") { hasTime = true; showTime = true }
                        .scaledFont(13, weight: .medium, maxScale: 1.2)
                        .padding(.bottom, 8)
                }
            }
            Divider().overlay(WeekStyle.border)
            Button { withAnimation { showSteps.toggle() } } label: {
                fieldRow("Small steps", subtitle: "Break this activity into smaller steps") {
                    valuePill(showSteps ? "Hide" : (activity.smallSteps.isEmpty ? "Add" : "Edit"))
                }
            }
            .buttonStyle(.plain)
            if showSteps {
                TextField("One small step per line", text: $activity.smallSteps, axis: .vertical)
                    .lineLimit(3...6).bodyText().padding(.bottom, 12)
                    .accessibilityLabel("Small steps")
            }
            Divider().overlay(WeekStyle.border)
            Button { withAnimation { showNotes.toggle() } } label: {
                fieldRow("Notes", subtitle: "Materials or links") {
                    valuePill(showNotes ? "Hide" : (activity.notes.isEmpty ? "Add" : "Edit"))
                }
            }
            .buttonStyle(.plain)
            if showNotes {
                TextField("Add materials, links or a note", text: $activity.notes, axis: .vertical)
                    .lineLimit(3...6).bodyText().padding(.bottom, 12)
                    .accessibilityLabel("Notes")
            }
        }
        .padding(.horizontal, 14)
        .weekFormCard()
    }

    private var saveFooter: some View {
        VStack(spacing: 6) {
            Button {
                activity.title = title
                activity.time = hasTime ? chosenTime : nil
                let choseFromSyllabus = activeSource == .syllabus && activity.syllabusTopicID != nil
                if !choseFromSyllabus, activity.title != originalActivity.title || activity.subject != originalActivity.subject {
                    activity.syllabusTopicID = nil
                }
                activity.isSyllabusGenerated = false
                onSave(activity)
                dismiss()
            } label: {
                Text(isEditing ? "Save activity" : "Add to your week")
                    .scaledFont(16, weight: .semibold, maxScale: 1.2)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 46)
                    .background(Theme.buttonFill.opacity(title.isEmpty ? 0.45 : 1), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(title.isEmpty || (activity.reminder && !hasTime))
            Text("Changes save to your weekly plan.")
                .scaledFont(11, maxScale: 1.2)
                .foregroundStyle(WeekStyle.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 10)
        .background(Theme.background)
    }

    private func fieldRow<Value: View>(_ title: String, subtitle: String? = nil, @ViewBuilder value: () -> Value) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).scaledFont(15, weight: .medium, maxScale: 1.2)
                if let subtitle {
                    Text(subtitle).scaledFont(11, maxScale: 1.2).foregroundStyle(WeekStyle.secondary)
                }
            }
            Spacer(minLength: 0)
            value()
        }
        .foregroundStyle(Theme.ink)
        .frame(minHeight: subtitle == nil ? 42 : 52)
        .contentShape(Rectangle())
    }

    private func valuePill(_ text: String) -> some View {
        HStack(spacing: 7) {
            Text(text).scaledFont(14, maxScale: 1.2)
            Image(systemName: "chevron.down").font(.system(size: 10))
        }
        .padding(.horizontal, 11).padding(.vertical, 5)
        .background(WeekStyle.field, in: Capsule())
    }

    private func durationPicker(_ field: DurationField) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(field == .learning ? "Learning time" : "Your help").sectionTitle()
            Text(field == .learning ? "Total time for this activity." : "Your help is included in the learning time.").caption()
            Picker("Minutes", selection: field == .learning ? $activity.minutes : $activity.helpMinutes) {
                ForEach(field == .learning ? Array(stride(from: 5, through: 480, by: 5)) : Array(stride(from: 0, through: activity.minutes, by: 5)), id: \.self) { minutes in
                    Text("\(minutes) min").tag(minutes)
                }
            }
            .pickerStyle(.wheel).frame(height: 120)
            Button("Done") { durationEditor = nil }.buttonStyle(.primaryHomeschool)
        }
        .padding(24)
        .background(Theme.background)
    }
}

private extension View {
    func weekFormCard() -> some View {
        background(Theme.surface, in: .rect(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(WeekStyle.border, lineWidth: 0.8))
    }
}

/// A searchable list of one subject's chapters and topics, used when adding a task from the syllabus.
private struct SyllabusTopicPicker: View {
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
