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

/// Whether the child is registered for the next NIOS exams, the last date for their level, and a reminder switch.
struct ExamSection: View {
    let child: Child
    @Environment(AppState.self) private var state
    @Environment(\.openURL) private var openURL

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    private func update(_ change: (inout Child) -> Void) {
        var changed = child
        change(&changed)
        state.updateChild(changed)
    }

    private var divider: some View {
        Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1).padding(.leading, 52)
    }

    var body: some View {
        VStack(spacing: 0) {
            if let window = child.examWindow {
                registeredRow(window)
                if !child.isExamRegistered {
                    divider
                    lastDateRow(window)
                    divider
                    reminderRow
                }
            } else {
                obeRow
            }
        }
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
        .task { notificationStatus = await ExamReminders.authorizationStatus() }
    }

    // MARK: Rows

    private func registeredRow(_ window: ExamWindow) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.tabSelected)
                .frame(width: 28)
            Toggle(isOn: Binding(
                get: { child.isExamRegistered },
                set: { value in update { $0.examRegisteredSession = value ? window.id : nil } })) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(window.session)
                        .scaledFont(12, weight: .medium, maxScale: 1.2)
                        .foregroundStyle(Theme.secondary)
                    Text(child.isExamRegistered ? "Registered" : "Not registered yet")
                        .scaledFont(16, weight: .medium, maxScale: 1.25)
                        .foregroundStyle(Theme.ink)
                }
            }
            .tint(Theme.tabSelected)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func lastDateRow(_ window: ExamWindow) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(child.examNeedsAttention ? Color.orange : Theme.tabSelected)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text("Last date to register")
                    .scaledFont(12, weight: .medium, maxScale: 1.2)
                    .foregroundStyle(Theme.secondary)
                Text(window.lastDate.formatted(date: .long, time: .omitted))
                    .scaledFont(16, weight: .medium, maxScale: 1.25)
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 6) {
                    Text(countdownText)
                        .scaledFont(13, weight: .medium, maxScale: 1.25)
                        .foregroundStyle(countdownColor)
                    if !window.isConfirmed {
                        Text("· Expected")
                            .scaledFont(13, maxScale: 1.25)
                            .foregroundStyle(Theme.secondary)
                    }
                }
            }
            Spacer(minLength: 8)
            Button { openURL(ExamCalendar.noticeURL) } label: {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.tabSelected)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Check the NIOS notice")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var reminderRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.tabSelected)
                    .frame(width: 28)
                Toggle(isOn: Binding(
                    get: { child.examRemindersOn && notificationStatus != .denied },
                    set: { setReminders($0) })) {
                    Text("Remind me")
                        .scaledFont(16, weight: .medium, maxScale: 1.25)
                        .foregroundStyle(Theme.ink)
                }
                .tint(Theme.tabSelected)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if notificationStatus == .denied {
                Button("Notifications are off. Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                .scaledFont(13, weight: .semibold, maxScale: 1.25)
                .foregroundStyle(Theme.tabSelected)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 54)
                .padding(.bottom, 12)
            }
        }
    }

    private var obeRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.tabSelected)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text("NIOS exams")
                    .scaledFont(12, weight: .medium, maxScale: 1.2)
                    .foregroundStyle(Theme.secondary)
                Text(ExamCalendar.obeNote)
                    .scaledFont(16, weight: .medium, maxScale: 1.25)
                    .foregroundStyle(Theme.ink)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
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
        guard let days = child.daysUntilExamDeadline else { return Theme.ink }
        if days <= 7 { return Color.red }
        return days <= 30 ? Color.orange : Theme.secondary
    }
}
