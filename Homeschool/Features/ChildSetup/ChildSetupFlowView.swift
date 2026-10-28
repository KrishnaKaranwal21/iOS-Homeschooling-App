import SwiftUI

/// First-time setup right after sign-up.
struct ChildSetupFlowView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var bindableState = state
        return ChildSetupSteps(child: $bindableState.child, mode: .onboarding) {
            state.advance(to: .main)
        }
    }
}

/// The three setup pages. Used for onboarding, adding another child and editing a child.
struct ChildSetupSteps: View {
    enum Mode { case onboarding, addChild, editChild }

    @Binding var child: Child
    var mode: Mode = .onboarding
    var onFinish: () -> Void
    var onCancel: (() -> Void)? = nil
    /// Edit just one page and save, with no Back or Continue through the others.
    var singleStep = false

    @State private var step: Int
    @State private var attempted = false
    @State private var continueAlert: String?

    init(child: Binding<Child>, mode: Mode = .onboarding, startStep: Int = 1, singleStep: Bool = false,
         onCancel: (() -> Void)? = nil, onFinish: @escaping () -> Void) {
        _child = child
        self.mode = mode
        self.singleStep = singleStep
        self.onCancel = onCancel
        self.onFinish = onFinish
        _step = State(initialValue: startStep)
    }

    private var finishTitle: String {
        switch mode {
        case .onboarding: return "Go to Home"
        case .addChild:   return child.name.trimmingCharacters(in: .whitespaces).isEmpty ? "Add child" : "Add \(child.displayName)"
        case .editChild:  return "Save changes"
        }
    }

    private var canContinue: Bool {
        switch step {
        case 1:
            return child.isBasicsComplete
        case 2:
            let data = Curriculum.data(for: child.level)
            return data.isComplete(selected: child.selectedSubjects)
        default:
            return true
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            header
            ScrollView(showsIndicators: false) {
                stepContent
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 12)
            }
            // A new identity per page, so each page opens at the top instead of keeping the last scroll position.
            .id(step)
            // The scroll view reserves room for the bar, and content scrolls beneath its blur.
            .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        }
        .foregroundStyle(Theme.obsidian)
        .background(Theme.background.ignoresSafeArea())
        .onChange(of: step) { attempted = false }
        .alert("Can't continue yet", isPresented: Binding(
            get: { continueAlert != nil },
            set: { if !$0 { continueAlert = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(continueAlert ?? "")
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 14) {
            if singleStep {
                HStack {
                    if let onCancel {
                        Button("Cancel", action: onCancel)
                            .foregroundStyle(Theme.obsidian)
                    }
                    Spacer()
                    Text(step == 2 ? "Subjects" : "Learning rhythm")
                        .scaledFont(12, weight: .semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.pillFill))
                }
            } else {
            HStack {
                if step > 1 {
                    Button { step -= 1 } label: { Label("Back", systemImage: "chevron.left") }
                        .foregroundStyle(Theme.obsidian)
                } else if let onCancel {
                    Button("Cancel", action: onCancel)
                        .foregroundStyle(Theme.obsidian)
                }
                Spacer()
                Text("0\(step) / 03")
                    .scaledFont(12, weight: .semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Theme.pillFill))
            }
            HStack(spacing: 6) {
                ForEach(1...3, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? Theme.obsidian : Theme.checkBorder.opacity(0.5))
                        .frame(height: 3)
                }
            }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: Pinned bottom bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            // Soft blur that fades the list out as it slides under the bar.
            fadeStrip.frame(height: 32)

            // Solid area behind the hint and button, so nothing shows through the text.
            VStack(spacing: 10) {
                if step <= 2 {
                    hintLabel
                } else {
                    Text("Review the plan before you save. Change it any time.")
                        .font(.caption)
                        .foregroundStyle(Theme.systemGray)
                }
                Button((step == 3 || singleStep) ? finishTitle : "Continue") {
                    handleContinue()
                }
                .buttonStyle(.primaryHomeschool(isDimmed: !canContinue))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.background.ignoresSafeArea(edges: .bottom))
        }
    }

    private var fadeStrip: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask { LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom) }
            LinearGradient(colors: [Theme.background.opacity(0), Theme.background],
                           startPoint: .top, endPoint: .bottom)
        }
    }

    private var hintText: String? {
        if step == 1 {
            return child.isBasicsComplete
                ? nil
                : "Enter a name, pick a date of birth and choose a level to continue."
        }
        let data = Curriculum.data(for: child.level)
        return data.hint(selected: child.selectedSubjects)
    }

    /// Step 2 only: a friendly note when more than the minimum number of subjects is chosen.
    private var extraNote: String? {
        guard step == 2 else { return nil }
        return Curriculum.data(for: child.level)
            .extraSubjectsNote(selected: child.selectedSubjects)
    }

    private var hintLabel: some View {
        Label(hintText ?? extraNote ?? "All set. Tap Continue.",
              systemImage: hintText != nil ? "info.circle" : (extraNote != nil ? "plus.circle" : "checkmark.circle.fill"))
            .font(.footnote.weight(.medium))
            .foregroundStyle(hintColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hintColor: Color {
        if hintText == nil { return Theme.obsidian }
        return attempted ? Color.red : Theme.systemGray
    }

    private var problemMessage: String {
        if step == 1 {
            return "Enter a name, pick a date of birth and choose a level to continue."
        }
        let data = Curriculum.data(for: child.level)
        let list = data.issues(selected: child.selectedSubjects)
        return list.isEmpty ? "Please review your selection." : list.joined(separator: "\n")
    }

    private func handleContinue() {
        guard canContinue else {
            attempted = true
            continueAlert = problemMessage
            return
        }
        if step < 3 && !singleStep {
            withAnimation { step += 1 }
        } else {
            onFinish()
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 1: ChildBasicsStep(child: $child)
        case 2: SubjectsStep(child: $child, showErrors: attempted)
        default: RhythmStep(child: $child)
        }
    }
}

// MARK: - Step 1

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
            Text("A nickname is absolutely fine")
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
                Image(systemName: "chevron.up.chevron.down").font(.footnote)
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
                Image(systemName: "chevron.up.chevron.down").font(.footnote)
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

// MARK: - Step 3

struct RhythmStep: View {
    @Binding var child: Child
    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private var weeklyHours: Int { child.learningDays.count * child.hoursPerDay }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SetupHeader(title: "A little structure. Plenty of room.", subtitle: "What feels doable for your child?")
            daysCard
            HStack(spacing: 12) {
                StepperCard(title: "Learning time", unit: "hours / day",
                            value: $child.hoursPerDay, range: 1...8, color: Theme.pink)
                StepperCard(title: "Your help", unit: "hours / day, up to",
                            value: $child.supportHours, range: 0...8, color: Theme.lavender)
            }
            weeklySummary
            dayRunCard
        }
    }

    // MARK: Learning days

    private var daysCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Choose your learning days").cardTitle()
                Text("Tap the days that usually work")
                    .font(.footnote)
                    .foregroundStyle(Theme.systemGray)
            }
            HStack(spacing: 8) {
                ForEach(Array(days.enumerated()), id: \.offset) { i, d in
                    dayCell(index: i, day: d)
                }
            }
            Text("\(child.learningDays.count) \(child.learningDays.count == 1 ? "day" : "days") selected")
                .font(.footnote)
                .foregroundStyle(Theme.systemGray)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .insetCard()
    }

    private func dayCell(index: Int, day: String) -> some View {
        let isOn = child.learningDays.contains(day)
        let isWeekend = index >= 5
        let fill: Color = isOn ? Theme.pink : (isWeekend ? Theme.pillFill : Color.white)
        return Button {
            if isOn { child.learningDays.remove(day) } else { child.learningDays.insert(day) }
        } label: {
            Text(Child.weekdays[index])
                .scaledFont(17, weight: .medium)
                .foregroundStyle(Theme.obsidian)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(fill, in: .rect(cornerRadius: 16))
                .roundedStroke(isOn ? Color.clear : Theme.cardBorder, cornerRadius: 16, lineWidth: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    // MARK: Weekly total

    private var weeklySummary: some View {
        HStack(spacing: 12) {
            calendarBadge
            Text("\(weeklyHours == 1 ? "hour" : "hours") of learning across the week")
                .font(.subheadline)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.pillFill, in: .rect(cornerRadius: 12))
    }

    // MARK: How should the day run?

    private var dayRunCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How should the day run?").cardTitle()
            modeToggle
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .insetCard()
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton("Flexible order", flexible: true)
            modeButton("Set times", flexible: false)
        }
        .padding(4)
        .background(Theme.pillFill, in: .rect(cornerRadius: 14))
    }

    private func modeButton(_ title: String, flexible: Bool) -> some View {
        let selected = child.flexibleOrder == flexible
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { child.flexibleOrder = flexible }
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(selected ? Theme.obsidian : Theme.systemGray)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(selected ? Color.white : Color.clear, in: .rect(cornerRadius: 10))
                .roundedStroke(selected ? Theme.cardBorder : Color.clear, cornerRadius: 10, lineWidth: 1)
        }
        .buttonStyle(.plain)
    }

    private var calendarBadge: some View {
        Text("\(weeklyHours)")
            .scaledFont(12, weight: .bold)
            .foregroundStyle(Color.white)
            .frame(width: 26, height: 26)
            .background(Theme.obsidian, in: .rect(cornerRadius: 6))
    }
}

struct StepperCard: View {
    let title: String
    let unit: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).cardTitle()
            Text("\(value)").scaledFont(56, weight: .bold)
            Text(unit).font(.footnote).foregroundStyle(Theme.systemGray)
            stepper.padding(.top, 8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color, in: .rect(cornerRadius: Theme.insetRadius))
    }

    private var stepper: some View {
        HStack(spacing: 0) {
            stepButton("minus", enabled: value > range.lowerBound) { value -= 1 }
            Rectangle().fill(Theme.cardBorder).frame(width: 1, height: 24)
            stepButton("plus", enabled: value < range.upperBound) { value += 1 }
        }
        .frame(minHeight: 52)
        .background(Capsule().fill(Color.white))
    }

    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .scaledFont(20)
                .foregroundStyle(enabled ? Theme.obsidian : Theme.checkBorder)
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .disabled(!enabled)
    }
}
