import SwiftUI

struct ChildSetupFlowView: View {
    @EnvironmentObject var state: AppState
    @State private var step = 1
    @State private var attempted = false
    @State private var continueAlert: String?

    private var canContinue: Bool {
        switch step {
        case 1:
            return state.child.isBasicsComplete
        case 2:
            let data = Curriculum.data(for: state.child.level)
            return data.isComplete(selected: state.child.selectedSubjects)
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
            HStack {
                if step > 1 {
                    Button { step -= 1 } label: { Label("Back", systemImage: "chevron.left") }
                        .foregroundStyle(Theme.obsidian)
                }
                Spacer()
                Text("0\(step) / 03")
                    .font(.system(size: 12, weight: .semibold))
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
                PrimaryButton(title: step == 3 ? "Lets build your RoadMap" : "Continue",
                              isDimmed: !canContinue) {
                    handleContinue()
                }
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
                .mask(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom))
            LinearGradient(colors: [Theme.background.opacity(0), Theme.background],
                           startPoint: .top, endPoint: .bottom)
        }
    }

    private var hintText: String? {
        if step == 1 {
            return state.child.isBasicsComplete
                ? nil
                : "Enter a name, choose a level and pick a date of birth to continue."
        }
        let data = Curriculum.data(for: state.child.level)
        return data.hint(selected: state.child.selectedSubjects)
    }

    private var hintLabel: some View {
        Label(hintText ?? "All set. Tap Continue.",
              systemImage: hintText == nil ? "checkmark.circle.fill" : "info.circle")
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
            return "Enter a name, choose a level and pick a date of birth to continue."
        }
        let data = Curriculum.data(for: state.child.level)
        let list = data.issues(selected: state.child.selectedSubjects)
        return list.isEmpty ? "Please review your selection." : list.joined(separator: "\n")
    }

    private func handleContinue() {
        guard canContinue else {
            attempted = true
            continueAlert = problemMessage
            return
        }
        if step < 3 {
            withAnimation { step += 1 }
        } else {
            state.advance(to: .main)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 1: ChildBasicsStep(child: $state.child)
        case 2: SubjectsStep(child: $state.child, showErrors: attempted)
        default: RhythmStep(child: $state.child)
        }
    }
}

// MARK: - Step 1

struct ChildBasicsStep: View {
    @Binding var child: Child
    @State private var draftDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SetupHeader(title: "Who are we planning for?", subtitle: "Start with one child. We'll keep this simple.")
            nameCard
            detailsCard
        }
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FIRST NAME OR NICKNAME")
                .font(.caption2).tracking(0.8).foregroundStyle(Theme.systemGray)
            TextField("Enter name", text: $child.name)
                .font(.largeTitle.bold())
                .textInputAutocapitalization(.words)
            Text("A nickname is absolutely fine")
                .font(.footnote)
                .foregroundStyle(Theme.systemGray)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.insetRadius, style: .continuous).fill(Theme.lavender))
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
                Text("Starting level")
                Spacer()
                levelMenu
            }
            divider
            HStack {
                Text("Date of birth")
                Spacer()
                dobPicker
            }
        }
        .padding(16)
        .insetCard()
    }

    private var divider: some View {
        Rectangle().fill(Theme.cardBorder).frame(height: 1)
    }

    private var levelMenu: some View {
        Menu {
            ForEach(Curriculum.levels, id: \.self) { level in
                Button(level) { child.level = level }
            }
        } label: {
            HStack(spacing: 4) {
                Text(child.level.isEmpty ? "Select" : child.level)
                Image(systemName: "chevron.up.chevron.down").font(.footnote)
            }
            .foregroundStyle(child.level.isEmpty ? Theme.systemGray : Theme.obsidian)
        }
    }

    // MARK: Date of birth (native calendar, styled like the level picker)

    private var dobText: String {
        if let date = child.birthDate {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
        return "Select"
    }

    private var dobBinding: Binding<Date> {
        Binding(
            get: { child.birthDate ?? draftDate },
            set: { newValue in
                draftDate = newValue
                child.birthDate = newValue
            }
        )
    }

    /// Our label (same look as the level menu) with the native compact date picker laid
    /// invisibly on top, so tapping it opens the system calendar with the system transition.
    private var dobPicker: some View {
        HStack(spacing: 4) {
            Text(dobText)
            Image(systemName: "chevron.up.chevron.down").font(.footnote)
        }
        .foregroundStyle(child.birthDate == nil ? Theme.systemGray : Theme.obsidian)
        .frame(minWidth: 130, alignment: .trailing)
        .overlay(alignment: .trailing) {
            DatePicker("Date of birth", selection: dobBinding, in: ...Date(), displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .colorMultiply(.clear)
        }
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
                Text("Choose your learning days").font(.headline)
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
        return Text(Child.weekdays[index])
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(Theme.obsidian)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isOn ? Color.clear : Theme.cardBorder, lineWidth: 1))
            .onTapGesture {
                if isOn { child.learningDays.remove(day) } else { child.learningDays.insert(day) }
            }
    }

    // MARK: Weekly total

    private var weeklySummary: some View {
        HStack(spacing: 12) {
            calendarBadge
            Text("\(weeklyHours) \(weeklyHours == 1 ? "hour" : "hours") of learning across the week")
                .font(.subheadline)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.pillFill))
    }

    // MARK: How should the day run?

    private var dayRunCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How should the day run?").font(.headline)
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
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.pillFill))
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
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selected ? Color.white : Color.clear))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(selected ? Theme.cardBorder : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var calendarBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Theme.obsidian)
                .frame(width: 26, height: 26)
            Text("\(weeklyHours)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.white)
        }
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
            Text(title).font(.headline)
            Text("\(value)").font(.system(size: 56, weight: .bold))
            Text(unit).font(.footnote).foregroundStyle(Theme.systemGray)
            stepper.padding(.top, 8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.insetRadius, style: .continuous).fill(color))
    }

    private var stepper: some View {
        HStack(spacing: 0) {
            stepButton("minus", enabled: value > range.lowerBound) { value -= 1 }
            Rectangle().fill(Theme.cardBorder).frame(width: 1, height: 24)
            stepButton("plus", enabled: value < range.upperBound) { value += 1 }
        }
        .frame(height: 52)
        .background(Capsule().fill(Color.white))
    }

    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .foregroundStyle(enabled ? Theme.obsidian : Theme.checkBorder)
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .disabled(!enabled)
    }
}
