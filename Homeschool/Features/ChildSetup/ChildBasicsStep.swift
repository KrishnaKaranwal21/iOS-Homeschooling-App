import SwiftUI

struct ChildBasicsStep: View {
    @Binding var child: Child
    @State private var draftDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
    @State private var showCalendar = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SetupHeader(title: "Who are we planning for?", subtitle: "Start with one child. We'll keep this simple.")
            nameCard
            detailsCard
            ageGuidance
        }
        .animation(.snappy, value: child.level)
        .animation(.snappy, value: child.birthDate)
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FIRST NAME OR NICKNAME")
                .font(.caption2).tracking(0.8).foregroundStyle(Theme.systemGray)
            TextField("Enter name", text: $child.name)
                .scaledFont(32, weight: .heavy, maxScale: 1.15)
                .tracking(-1)
                .textInputAutocapitalization(.words)
            Text("A nickname is absolutely fine.")
                .font(.footnote)
                .foregroundStyle(Theme.systemGray)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.lavender, in: .rect(cornerRadius: Theme.insetRadius))
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Curriculum")
                Spacer()
                Text("NIOS").foregroundStyle(Theme.systemGray)
            }
            divider
            HStack {
                Text("Date of birth")
                Spacer()
                dobPicker
            }
            divider
            HStack {
                Text("Starting level")
                Spacer()
                levelMenu
            }
        }
        .padding(16)
        .insetCard()
    }

    private var divider: some View {
        Rectangle().fill(Theme.cardBorder).frame(height: 1)
    }

    // MARK: Level

    private var levelMenu: some View {
        Menu {
            ForEach(Curriculum.levels, id: \.self) { level in
                Button("\(Curriculum.displayName(for: level)) · \(AgeRules.rule(for: level)?.grade ?? "")") {
                    child.level = level
                    child.levelChosenManually = true
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(child.level.isEmpty ? "Select" : Curriculum.displayName(for: child.level))
                Image(systemName: "chevron.up.chevron.down").accessibilityHidden(true).font(.footnote)
            }
            .foregroundStyle(child.level.isEmpty ? Theme.systemGray : Theme.obsidian)
        }
    }

    // MARK: Date of birth

    private var dobText: String {
        if let date = child.birthDate {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
        return "Select"
    }

    /// Picking a day saves it, suggests a level for that age, and closes the calendar.
    private var dobBinding: Binding<Date> {
        Binding(
            get: { child.birthDate ?? draftDate },
            set: { newValue in
                draftDate = newValue
                child.birthDate = newValue
                if !child.levelChosenManually {
                    child.level = AgeRules.suggestedLevel(for: newValue)
                }
                showCalendar = false
            }
        )
    }

    private var dobPicker: some View {
        Button { showCalendar = true } label: {
            HStack(spacing: 4) {
                Text(dobText)
                Image(systemName: "chevron.up.chevron.down").accessibilityHidden(true).font(.footnote)
            }
            .foregroundStyle(child.birthDate == nil ? Theme.systemGray : Theme.obsidian)
            .frame(minWidth: 130, alignment: .trailing)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showCalendar) {
            DatePicker("Date of birth", selection: dobBinding, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(12)
                .frame(width: 330)
                .presentationCompactAdaptation(.popover)
        }
    }

    // MARK: Age guidance (informs only, never blocks)

    @ViewBuilder
    private var ageGuidance: some View {
        if let birthDate = child.birthDate {
            VStack(alignment: .leading, spacing: 10) {
                guidanceRow(icon: "graduationcap", color: Theme.systemGray,
                            text: AgeRules.typicalNote(for: birthDate))

                if !child.level.isEmpty,
                   let warning = AgeRules.minimumAgeWarning(level: child.level, birthDate: birthDate, name: child.name) {
                    guidanceRow(icon: "exclamationmark.triangle.fill", color: .red, text: warning, bold: true)
                }
            }
            .padding(.horizontal, 4)
            .transition(.opacity)
        }
    }

    private func guidanceRow(icon: String, color: Color, text: String, bold: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.footnote.weight(bold ? .semibold : .regular))
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
