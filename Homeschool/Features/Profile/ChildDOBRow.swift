import SwiftUI

/// Tapping the row opens the calendar straight away, like the child setup page.
struct ChildDOBRow: View {
    let child: Child
    /// Called when the new date moved the child to another level, so the subjects need choosing again.
    let onLevelChanged: (Child) -> Void

    @Environment(AppState.self) private var state
    @State private var showCalendar = false
    @State private var draftDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()

    private var text: String {
        guard let date = child.birthDate else { return "Not set" }
        return date.formatted(date: .long, time: .omitted)
    }

    private var binding: Binding<Date> {
        Binding(
            get: { child.birthDate ?? draftDate },
            set: { newValue in
                draftDate = newValue
                var updated = child
                updated.birthDate = newValue
                var levelChanged = false
                if !updated.levelChosenManually {
                    let suggested = AgeRules.suggestedLevel(for: newValue)
                    if suggested != updated.level {
                        updated.level = suggested
                        updated.selectedSubjects = []
                        levelChanged = true
                    }
                }
                state.updateChild(updated)
                showCalendar = false
                if levelChanged { onLevelChanged(updated) }
            }
        )
    }

    var body: some View {
        Button { showCalendar = true } label: {
            ProfileInfoRow(symbol: "calendar", title: "Date of birth", value: text)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Date of birth, \(text). Edit")
        .popover(isPresented: $showCalendar) {
            DatePicker("Date of birth", selection: binding, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(12)
                .frame(width: 330)
                .presentationCompactAdaptation(.popover)
        }
    }
}
