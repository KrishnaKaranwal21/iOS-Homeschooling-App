import SwiftUI

struct ChildSetupFlowView: View {
    @EnvironmentObject var state: AppState
    @State private var step = 1

    private var canContinue: Bool {
        guard step == 2 else { return true }
        let data = Curriculum.data(for: state.child.level)
        return data.isComplete(selected: state.child.selectedSubjects)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                if step > 1 {
                    Button { step -= 1 } label: { Label("Back", systemImage: "chevron.left") }
                }
                Spacer()
                Text("0\(step) / 03").font(.caption).padding(8).background(Theme.field, in: Capsule())
            }
            HStack(spacing: 6) {
                ForEach(1...3, id: \.self) { i in
                    Capsule().fill(i <= step ? Theme.ink : Theme.field).frame(height: 3)
                }
            }
            ScrollView {
                stepContent
            }
            PrimaryButton(title: step == 3 ? "Lets build your RoadMap" : "Continue") {
                if step < 3 { withAnimation { step += 1 } } else { state.advance(to: .main) }
            }
            .disabled(!canContinue)
            .opacity(canContinue ? 1 : 0.4)
        }
        .padding()
        .background(Theme.background)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 1: ChildBasicsStep(child: $state.child)
        case 2: SubjectsStep(child: $state.child)
        default: RhythmStep(child: $state.child)
        }
    }
}

struct ChildBasicsStep: View {
    @Binding var child: Child

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScreenHeader(title: "Who are we planning for?", subtitle: "Start with one child. We'll keep this simple.")

            Card(color: Theme.lavender) {
                VStack(alignment: .leading) {
                    Eyebrow("First name or nickname")
                    TextField("Name", text: $child.name).font(.largeTitle.bold())
                    Text("A nickname is absolutely fine")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondary)
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Curriculum")
                        Spacer()
                        Text("NIOS").foregroundStyle(Theme.secondary)
                    }
                    Divider()
                    HStack {
                        Text("Starting level")
                        Spacer()
                        Picker("Starting level", selection: $child.level) {
                            ForEach(Curriculum.levels, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    Divider()
                    DatePicker("Date of birth", selection: $child.birthDate, displayedComponents: .date)
                }
            }
        }
    }
}

struct RhythmStep: View {
    @Binding var child: Child
    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScreenHeader(title: "A little structure. Plenty of room.", subtitle: "What feels doable for your child?")
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose your learning days").font(.headline)
                    HStack {
                        ForEach(Array(days.enumerated()), id: \.offset) { i, d in
                            dayCell(index: i, day: d)
                        }
                    }
                    Text("\(child.learningDays.count) days selected")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondary)
                }
            }
            HStack(spacing: 12) {
                StepperCard(title: "Learning time", unit: "hours / day", value: $child.hoursPerDay, color: Theme.pink)
                StepperCard(title: "Your help", unit: "hours / day, up to", value: $child.supportHours, color: Theme.lavender)
            }
        }
    }

    private func dayCell(index: Int, day: String) -> some View {
        let isOn = child.learningDays.contains(day)
        return Text(Child.weekdays[index])
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(RoundedRectangle(cornerRadius: 12).fill(isOn ? Theme.pink : Theme.field))
            .onTapGesture {
                if isOn { child.learningDays.remove(day) } else { child.learningDays.insert(day) }
            }
    }
}

struct StepperCard: View {
    let title: String
    let unit: String
    @Binding var value: Int
    let color: Color

    var body: some View {
        Card(color: color) {
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text("\(value)").font(.system(size: 56, weight: .bold))
                Text(unit).font(.footnote).foregroundStyle(Theme.secondary)
                Stepper("", value: $value, in: 1...8).labelsHidden()
            }
        }
    }
}
