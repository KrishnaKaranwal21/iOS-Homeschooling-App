import SwiftUI

/// Child-setup step for choosing learning days and hours per day.
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
        let fill: Color = isOn ? Theme.pink : (isWeekend ? Theme.pillFill : Theme.surface)
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

    private var calendarBadge: some View {
        Text("\(weeklyHours)")
            .scaledFont(12, weight: .bold)
            .foregroundStyle(Color.white)
            .frame(width: 26, height: 26)
            .background(Theme.buttonFill, in: .rect(cornerRadius: 6))
    }
}

/// A large number with plus and minus buttons, used to pick a count within a range.
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
        .background(Capsule().fill(Theme.surface))
    }

    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .scaledFont(20)
                .foregroundStyle(enabled ? Theme.obsidian : Theme.checkBorder)
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .disabled(!enabled)
        .accessibilityLabel("\(symbol == "plus" ? "Increase" : "Decrease") \(title)")
    }
}
