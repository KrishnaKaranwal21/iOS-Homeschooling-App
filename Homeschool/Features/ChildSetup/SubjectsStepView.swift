import SwiftUI

struct SubjectsStep: View {
    @Binding var child: Child
    var showErrors: Bool = false
    @State private var showMore = false
    @State private var touched: Set<String> = []
    @State private var alertMessage: String?

    private var curriculum: LevelCurriculum { Curriculum.data(for: child.level) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SetupHeader(title: "Follow their rabbit holes.")
            InterestsCard(interests: $child.interests, showMore: $showMore)
            ForEach(curriculum.groups) { group in
                SubjectGroupSection(group: group, curriculum: curriculum,
                                    selected: child.selectedSubjects,
                                    issue: issue(for: group)) { option in
                    toggle(group, option)
                }
            }
        }
        .onAppear(perform: syncSelection)
        .alert("Selection rule", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    // MARK: Selection logic

    private func toggle(_ group: SubjectGroup, _ option: SubjectOption) {
        guard !group.locked else { return }
        touched.insert(group.id)
        let key = SubjectKey.make(group, option)
        var current = child.selectedSubjects
        let c = curriculum.count(in: group, selected: current)

        // Deselecting is always allowed. Problems show in red and when tapping Continue.
        if current.contains(key) {
            current.remove(key)
            child.selectedSubjects = current
            alertMessage = fullLoadWarning(for: current)
            return
        }

        // Selecting: total ceiling
        let alreadyCounted = curriculum.groups.contains { g in
            g.options.contains { $0.name == option.name && curriculum.isSelected(g, $0, in: current) }
        }
        let total = curriculum.uniqueTotal(selected: current)
        if let maxTotal = curriculum.maxSubjects, !alreadyCounted, total >= maxTotal {
            alertMessage = "You can select at most \(maxTotal) subjects in total."
            return
        }

        // Selecting: group ceiling
        if let base = group.maxPick, c >= base {
            if let full = group.maxPickAtFullLoad, c < full {
                current.insert(key)
                child.selectedSubjects = current
                // Only warn when the extra language does not bring the total to the ceiling.
                alertMessage = fullLoadWarning(for: current)
                return
            }
            if base == 1 {
                alertMessage = "Only 1 \(group.unit) can be selected in \(group.title). Remove the current one first."
            } else {
                alertMessage = "Only \(base) \(Curriculum.plural(base, group.unit)) can be selected in \(group.title)."
            }
            return
        }

        current.insert(key)
        child.selectedSubjects = current
    }

    private func issue(for group: SubjectGroup) -> String? {
        guard touched.contains(group.id) || showErrors else { return nil }
        return curriculum.groupIssue(group, selected: child.selectedSubjects)
    }

    /// Warns when a 3rd language is selected but the total is below the full subject ceiling.
    private func fullLoadWarning(for selection: Set<String>) -> String? {
        guard let cap = curriculum.maxSubjects else { return nil }
        let total = curriculum.uniqueTotal(selected: selection)
        for group in curriculum.groups {
            guard let base = group.maxPick, group.maxPickAtFullLoad != nil else { continue }
            if curriculum.count(in: group, selected: selection) > base && total < cap {
                return "A 3rd \(group.unit) counts only when you register all \(cap) subjects. Add more subjects to reach \(cap)."
            }
        }
        return nil
    }

    private func syncSelection() {
        var validKeys = Set<String>()
        for group in curriculum.groups {
            for option in group.options { validKeys.insert(SubjectKey.make(group, option)) }
        }

        var result = Set(child.selectedSubjects.filter { validKeys.contains($0) })

        for group in curriculum.groups {
            if group.locked {
                for option in group.options { result.insert(SubjectKey.make(group, option)) }
                continue
            }
            let hasAny = group.options.contains { result.contains(SubjectKey.make(group, $0)) }
            if !hasAny {
                for name in group.preselect {
                    if let option = group.options.first(where: { $0.name == name }) {
                        result.insert(SubjectKey.make(group, option))
                    }
                }
            }
        }
        child.selectedSubjects = result
    }
}

struct SubjectGroupSection: View {
    let group: SubjectGroup
    let curriculum: LevelCurriculum
    let selected: Set<String>
    let issue: String?
    let onToggle: (SubjectOption) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            rows
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(group.title)
                    .cardTitle()
                Spacer(minLength: 8)
                StatusPill(text: statusText, state: pillState)
            }
            if let issue {
                Label(issue, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.red)
            }
        }
    }

    private var chosen: Int { curriculum.count(in: group, selected: selected) }

    private var pillState: StatusPill.State {
        if group.locked { return .required }
        if issue != nil { return .problem }
        return curriculum.isGroupSatisfied(group, selected: selected) && chosen > 0 ? .done : .pending
    }

    /// Short and numeric, e.g. "0 of 1–2". The long rule text is no longer repeated.
    private var statusText: String {
        if group.locked { return "Required" }
        let minValue = curriculum.effectiveMin(group, selected: selected)
        if let maxValue = group.maxPick {
            if minValue == maxValue || minValue == 0 { return "\(chosen) of \(maxValue)" }
            return "\(chosen) of \(minValue)–\(maxValue)"
        }
        if minValue > 0 { return "\(chosen) of \(minValue)+" }
        return "\(chosen) chosen"
    }

    private var rows: some View {
        VStack(spacing: 0) {
            ForEach(group.options) { option in
                SubjectRow(group: group, option: option,
                           isOn: curriculum.isSelected(group, option, in: selected)) {
                    onToggle(option)
                }
                if option.id != group.options.last?.id {
                    Rectangle()
                        .fill(Theme.cardBorder)
                        .frame(height: 1)
                        .padding(.leading, 52)
                }
            }
        }
        .insetCard()
    }
}
