import SwiftUI

struct WeekTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    let week: WeeklyPlan
    let isEditing: Bool
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

    private enum DurationField: String, Identifiable {
        case learning, help
        var id: String { rawValue }
    }

    private let subjects = ["Coding", "Maths", "English", "Science", "Computer skills", "Art & craft", "Reading", "Life skills"]

    init(activity: WeekActivity, week: WeeklyPlan, isEditing: Bool, onSave: @escaping (WeekActivity) -> Void) {
        self.week = week
        self.isEditing = isEditing
        self.onSave = onSave
        _activity = State(initialValue: activity)
        _hasTime = State(initialValue: activity.time != nil)
        _chosenTime = State(initialValue: activity.time ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: activity.date)!)
        _showSteps = State(initialValue: !activity.smallSteps.isEmpty)
        _showNotes = State(initialValue: !activity.notes.isEmpty)
    }

    private var title: String { activity.title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var subjectOptions: [String] { Array(Set(subjects + week.activities.map(\.subject))).sorted() }

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
                        .background(WeekStyle.field, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close task")
            }
            .padding(.horizontal, 22).padding(.top, 26).padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    activityCard
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
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACTIVITY")
                .scaledFont(11, weight: .semibold, maxScale: 1.2)
                .foregroundStyle(WeekStyle.secondary).tracking(0.5)
            TextField("Explore Python\ndata types", text: $activity.title, axis: .vertical)
                .scaledFont(28, weight: .bold, maxScale: 1.2)
                .lineLimit(2...4)
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
                .background(Color.adaptive(0xECEAF6, 0x30283F), in: Capsule())
                .overlay(Capsule().strokeBorder(.white, lineWidth: 1))
            }
            .accessibilityLabel("Subject, \(activity.subject)")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.adaptive(0xEEEEEE, 0x303033), in: .rect(cornerRadius: 16))
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
                onSave(activity)
                dismiss()
            } label: {
                Text(isEditing ? "Update weekly draft" : "Add to weekly draft")
                    .scaledFont(16, weight: .semibold, maxScale: 1.2)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 46)
                    .background(Theme.buttonFill.opacity(title.isEmpty ? 0.45 : 1), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(title.isEmpty || (activity.reminder && !hasTime))
            Text("Check the day’s total before saving your week.")
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
