import SwiftUI

// MARK: - StatusPill

/// A small coloured label showing the state of a subject or a requirement.
struct StatusPill: View {
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

// MARK: - SubjectRow

/// One selectable subject in a group; locked groups show it as fixed.
struct SubjectRow: View {
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

// MARK: - SelectionIndicator

/// The round check mark that shows whether a row is selected or locked.
struct SelectionIndicator: View {
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

// MARK: - SubjectIcon

/// Maps a subject name to the SF Symbol used beside it.
enum SubjectIcon {
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
        // Every symbol in `map` ships with the deployment target (iOS 18), so a plain lookup is enough.
        return map[name] ?? fallback
    }
}
