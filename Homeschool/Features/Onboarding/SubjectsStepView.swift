import SwiftUI

struct SubjectsStep: View {
    @Binding var child: Child
    @State private var showMore = false
    @State private var alertMessage: String?

    private var curriculum: LevelCurriculum { Curriculum.data(for: child.level) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScreenHeader(title: "Follow their rabbit holes.")
            InterestsCard(interests: $child.interests, showMore: $showMore)
            RequirementsCard(curriculum: curriculum, selected: child.selectedSubjects)
            ForEach(curriculum.groups) { group in
                SubjectGroupSection(group: group, curriculum: curriculum,
                                    selected: child.selectedSubjects) { option in
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
        let key = SubjectKey.make(group, option)
        var current = child.selectedSubjects
        let c = curriculum.count(in: group, selected: current)

        // Deselecting
        if current.contains(key) {
            if c - 1 < group.minPick {
                let n = group.minPick
                alertMessage = "At least \(n) \(Curriculum.plural(n, group.unit)) must stay selected in \(group.title)."
                return
            }
            current.remove(key)
            child.selectedSubjects = current
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
            if let full = group.maxPickAtFullLoad, c < full, let cap = curriculum.maxSubjects {
                current.insert(key)
                child.selectedSubjects = current
                alertMessage = "A 3rd \(group.unit) counts only when you register all \(cap) subjects. Add more subjects to reach \(cap)."
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
            Eyebrow("Pick what feels like them")
                .frame(maxWidth: .infinity)
            FlowLayout(spacing: 10) {
                ForEach(visible) { item in
                    OutlinedChip(title: item.name, systemImage: item.symbol,
                                 selected: interests.contains(item.name))
                        .onTapGesture { toggle(item.name) }
                }
                OutlinedChip(title: showMore ? "Less" : "More")
                    .onTapGesture { withAnimation { showMore.toggle() } }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 28).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Theme.dotInactive, lineWidth: 1))
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
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 20).fill(selected ? Theme.pink : Color.white))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.dotInactive, lineWidth: 1))
    }
}

// MARK: - Requirements card

private struct RequirementsCard: View {
    let curriculum: LevelCurriculum
    let selected: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(curriculum.level) · \(curriculum.equivalent)").font(.headline)
                Text(curriculum.summary).font(.footnote).foregroundStyle(Theme.secondary)
            }

            Divider()

            Text("WHAT YOU NEED").font(.caption2).tracking(0.8).foregroundStyle(Theme.secondary)
            ForEach(curriculum.requirements(selected: selected)) { item in
                RequirementRow(item: item)
            }

            Label("Tap a subject to add or remove it. Required subjects are added for you.",
                  systemImage: "hand.tap")
                .font(.footnote)
                .foregroundStyle(Theme.secondary)
                .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24).fill(Theme.lavender.opacity(0.55)))
    }
}

private struct RequirementRow: View {
    let item: Requirement
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.met ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(item.met ? Theme.ink : Theme.secondary)
            Text(item.title).font(.subheadline.weight(.medium))
            Spacer()
            Text(item.detail).font(.footnote).foregroundStyle(Theme.secondary)
        }
    }
}

// MARK: - Subject groups

private struct SubjectGroupSection: View {
    let group: SubjectGroup
    let curriculum: LevelCurriculum
    let selected: Set<String>
    let onToggle: (SubjectOption) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            rows
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(group.title).font(.title3.bold())
                Spacer()
                StatusPill(text: statusText, good: statusGood, locked: group.locked)
            }
            if let note = group.note {
                Text(note).font(.footnote).foregroundStyle(Theme.secondary)
            }
        }
    }

    private var chosen: Int { curriculum.count(in: group, selected: selected) }

    private var statusText: String {
        if group.locked { return "Required" }
        return "\(chosen) chosen · \(curriculum.rangeText(for: group, selected: selected))"
    }

    private var statusGood: Bool {
        group.locked || curriculum.isGroupSatisfied(group, selected: selected)
    }

    private var rows: some View {
        VStack(spacing: 0) {
            ForEach(group.options) { option in
                SubjectRow(group: group, option: option,
                           isOn: curriculum.isSelected(group, option, in: selected)) {
                    onToggle(option)
                }
                if option.id != group.options.last?.id {
                    Divider().padding(.leading, 40)
                }
            }
        }
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 24).fill(group.locked ? Theme.field.opacity(0.6) : Color.white))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.dotInactive, lineWidth: 1))
    }
}

private struct StatusPill: View {
    let text: String
    let good: Bool
    let locked: Bool

    var body: some View {
        HStack(spacing: 4) {
            if locked { Image(systemName: "lock.fill") }
            Text(text)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(pillColor))
    }

    private var pillColor: Color {
        if locked { return Theme.lavender }
        return good ? Theme.lime : Theme.yellow
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
        HStack(spacing: 14) {
            Image(systemName: SubjectIcon.symbol(for: option.name, groupId: group.id))
                .frame(width: 24)
            Text(option.name)
            if let code = option.code {
                Text("(\(code))").font(.caption).foregroundStyle(Theme.secondary)
            }
            Spacer()
            CheckBadge(isOn: isOn, locked: group.locked)
        }
        .foregroundStyle(Theme.ink)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

private struct CheckBadge: View {
    let isOn: Bool
    let locked: Bool

    var body: some View {
        ZStack {
            Circle().fill(fillColor)
            Circle().stroke(isOn ? Color.clear : Theme.dotInactive, lineWidth: 1.5)
            if isOn {
                Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .foregroundStyle(locked ? Color.white : Theme.ink)
            }
        }
        .frame(width: 28, height: 28)
    }

    private var fillColor: Color {
        if !isOn { return Color.clear }
        return locked ? Theme.ink : Theme.pink
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
        if let s = map[name] { return s }
        return groupId.hasPrefix("lang") ? "character.book.closed" : "book.closed"
    }
}
