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

// MARK: - Interests

private struct Interest: Identifiable {
    let name: String
    let symbol: String
    var id: String { name }
}

private struct InterestsCard: View {
    @Binding var interests: Set<String>
    @Binding var showMore: Bool

    private let main = [
        Interest(name: "Coding", symbol: "chevron.left.forwardslash.chevron.right"),
        Interest(name: "Animals", symbol: "pawprint"),
        Interest(name: "Art", symbol: "paintpalette"),
        Interest(name: "Music", symbol: "music.note")
    ]
    private let extra = [
        Interest(name: "Space", symbol: "moon.stars"),
        Interest(name: "Nature", symbol: "leaf"),
        Interest(name: "Sports", symbol: "figure.run"),
        Interest(name: "Reading", symbol: "book")
    ]

    private var visible: [Interest] { showMore ? main + extra : main }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PICK WHAT FEELS LIKE THEM")
                .font(.caption2)
                .tracking(0.8)
                .foregroundStyle(Theme.systemGray)
                .frame(maxWidth: .infinity)
            FlowLayout(spacing: 10) {
                ForEach(visible) { item in
                    Button { toggle(item.name) } label: {
                        OutlinedChip(title: item.name, systemImage: item.symbol,
                                     selected: interests.contains(item.name))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(interests.contains(item.name) ? .isSelected : [])
                }
                Button { withAnimation { showMore.toggle() } } label: {
                    OutlinedChip(title: showMore ? "Less" : "More")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .insetCard()
    }

    private func toggle(_ name: String) {
        if interests.contains(name) { interests.remove(name) } else { interests.insert(name) }
    }
}

struct OutlinedChip: View {
    let title: String
    var systemImage: String? = nil
    var selected = false

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage { Image(systemName: systemImage) }
            Text(title)
            if selected { Image(systemName: "checkmark").font(.footnote.bold()) }
        }
        .foregroundStyle(Theme.obsidian)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(selected ? Theme.pink : Color.white))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(selected ? Color(hex: 0xEFB4B4) : Theme.cardBorder, lineWidth: 1))
    }
}

// MARK: - Subject groups

private struct SubjectGroupSection: View {
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

private struct StatusPill: View {
    enum State { case required, pending, done, problem }

    let text: String
    let state: State

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .scaledFont(12, weight: .semibold)
            Text(text)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .scaledFont(13, weight: .semibold)
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(background))
        .animation(.snappy, value: text)
        .animation(.snappy, value: state)
    }

    private var symbol: String {
        switch state {
        case .required: return "lock.fill"
        case .pending:  return "circle.dashed"
        case .done:     return "checkmark.circle.fill"
        case .problem:  return "exclamationmark.circle.fill"
        }
    }

    private var foreground: Color {
        switch state {
        case .required, .pending: return Theme.systemGray
        case .done:               return Color.green
        case .problem:            return Color.red
        }
    }

    private var background: Color {
        switch state {
        case .required, .pending: return Theme.pillFill
        case .done:               return Color.green.opacity(0.14)
        case .problem:            return Color.red.opacity(0.12)
        }
    }
}

private struct SubjectRow: View {
    let group: SubjectGroup
    let option: SubjectOption
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        if group.locked {
            content
        } else {
            Button(action: action) { content }
                .buttonStyle(.plain)
        }
    }

    private var content: some View {
        HStack(spacing: 12) {
            Image(systemName: SubjectIcon.symbol(for: option.name, groupId: group.id))
                .scaledFont(18)
                .frame(width: 24)
                .foregroundStyle(Theme.obsidian)
            Text(option.name).foregroundStyle(Theme.obsidian)
            if let code = option.code {
                Text("(\(code))").font(.caption).foregroundStyle(Theme.systemGray)
            }
            Spacer(minLength: 8)
            SelectionIndicator(isOn: isOn, locked: group.locked)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 54)
        .contentShape(Rectangle())
    }
}

private struct SelectionIndicator: View {
    let isOn: Bool
    let locked: Bool

    var body: some View {
        ZStack {
            Circle().fill(isOn ? Theme.pink : Color.clear)
            Circle().stroke(isOn ? Color.clear : Theme.checkBorder, lineWidth: 1.5)
            if isOn {
                Image(systemName: "checkmark")
                    .scaledFont(12, weight: .bold)
                    .foregroundStyle(Theme.obsidian)
            }
        }
        .frame(width: 28, height: 28)
    }
}

private enum SubjectIcon {
    private static let map: [String: String] = [
        "Mathematics": "function", "Basic Mathematics": "function",
        "Science": "testtube.2", "Science & Technology": "testtube.2",
        "Social Science": "globe", "English": "book",
        "Environmental Studies (EVS)": "leaf", "Environmental Science": "leaf",
        "Computer Skills": "desktopcomputer", "Basic Computing": "desktopcomputer",
        "Computer Science": "desktopcomputer", "Data Entry Operations": "keyboard",
        "Creative Crafts": "scissors", "Cutting & Tailoring": "scissors",
        "Basic Agriculture": "camera.macro", "Vermicomposting": "leaf.arrow.circlepath",
        "Basic Electrician & Plumbing": "wrench.and.screwdriver", "Carpentry": "hammer",
        "Solar Energy Technician": "sun.max", "Yoga": "figure.mind.and.body",
        "Yoga & Health": "figure.mind.and.body", "Painting": "paintbrush",
        "Economics": "chart.line.uptrend.xyaxis", "Business Studies": "briefcase",
        "Accountancy": "dollarsign.circle", "Home Science": "house", "Psychology": "brain.head.profile",
        "Physics": "atom", "Chemistry": "flask", "Biology": "leaf", "Geography": "map",
        "History": "clock.arrow.circlepath", "Political Science": "building.columns",
        "Sociology": "person.3", "Introduction to Law": "scalemass", "Tourism": "airplane",
        "Mass Communication": "megaphone", "Library & Information Science": "books.vertical",
        "Bakery & Confectionery": "birthday.cake", "Indian Culture & Heritage": "building.columns",
        "Certificate in Desktop Publishing": "doc.richtext"
    ]

    static func symbol(for name: String, groupId: String) -> String {
        let fallback = groupId.hasPrefix("lang") ? "character.book.closed" : "book.closed"
        // Never show a blank icon: if a symbol name isn't available on this iOS version, use the fallback.
        if let s = map[name], UIImage(systemName: s) != nil { return s }
        return fallback
    }
}
