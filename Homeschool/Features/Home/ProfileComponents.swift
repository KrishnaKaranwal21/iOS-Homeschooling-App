import SwiftUI
import UserNotifications

// MARK: - Level picker

/// Switch a child between NIOS levels without going through setup again.
struct LevelPickerSheet: View {
    let child: Child
    /// Called with the updated child when the level really changed, so the subjects page can open next.
    let onChanged: (Child) -> Void

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Curriculum.levels, id: \.self) { level in
                        Button {
                            if let changed = state.changeLevel(of: child.id, to: level) {
                                onChanged(changed)
                            }
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(Curriculum.displayName(for: level))
                                        .scaledFont(17, weight: .semibold, maxScale: 1.2)
                                        .foregroundStyle(Theme.ink)
                                    if let rule = AgeRules.rule(for: level) {
                                        Text("\(rule.grade) · minimum age \(rule.minimumAge)")
                                            .scaledFont(14, maxScale: 1.25)
                                            .foregroundStyle(Theme.secondary)
                                    }
                                }
                                Spacer()
                                if level == child.level {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(Theme.tabSelected)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .accessibilityAddTraits(level == child.level ? .isSelected : [])
                    }
                } footer: {
                    Text("Subjects depend on the level, so you’ll choose them again next. Everything else stays as it is.")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("NIOS level for \(child.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Exam registration

/// Rows for a child's NIOS exams, made to sit inside a grouped list: registered or not, the last date for the level,
/// and a reminder switch.
struct ExamRows: View {
    let child: Child
    @Environment(AppState.self) private var state
    @Environment(\.openURL) private var openURL

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    private func update(_ change: (inout Child) -> Void) {
        var changed = child
        change(&changed)
        state.updateChild(changed)
    }

    var body: some View {
        Group {
            if let window = child.examWindow {
                Toggle(isOn: Binding(
                    get: { child.isExamRegistered },
                    set: { value in update { $0.examRegisteredSession = value ? window.id : nil } })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Registered for exams")
                        Text(window.session)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if !child.isExamRegistered {
                    LabeledContent {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(window.lastDate.formatted(date: .abbreviated, time: .omitted))
                            Text(countdownText + (window.isConfirmed ? "" : " · expected"))
                                .font(.footnote)
                                .foregroundStyle(countdownColor)
                        }
                    } label: {
                        Text("Last date to register")
                    }

                    Button { openURL(ExamCalendar.noticeURL) } label: {
                        Label("Check the NIOS notice", systemImage: "arrow.up.right.square")
                    }

                    Toggle("Remind me", isOn: Binding(
                        get: { child.examRemindersOn && notificationStatus != .denied },
                        set: { setReminders($0) }))

                    if notificationStatus == .denied {
                        Button("Notifications are off. Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                        .font(.footnote)
                    }
                }
            } else {
                Label {
                    Text(ExamCalendar.obeNote)
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .task { notificationStatus = await ExamReminders.authorizationStatus() }
    }

    // MARK: Helpers

    private func setReminders(_ on: Bool) {
        guard on else {
            update { $0.examRemindersOn = false }
            return
        }
        Task {
            let granted = await ExamReminders.requestAuthorization()
            notificationStatus = await ExamReminders.authorizationStatus()
            update { $0.examRemindersOn = granted }
        }
    }

    private var countdownText: String {
        guard let days = child.daysUntilExamDeadline else { return "" }
        switch days {
        case ..<0:  return "Closed \(-days) \(-days == 1 ? "day" : "days") ago"
        case 0:     return "Closes today"
        case 1:     return "Closes tomorrow"
        default:    return "\(days) days left"
        }
    }

    private var countdownColor: Color {
        guard let days = child.daysUntilExamDeadline else { return .secondary }
        if days <= 7 { return .red }
        return days <= 30 ? .orange : .secondary
    }
}
