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
    /// The child as it was when this page opened, to see what the parent changed while editing.
    @State private var original: Child
    /// The level the subjects were last cleared for, so going back and forth doesn't clear them twice.
    @State private var subjectsClearedForLevel: String?

    init(child: Binding<Child>, mode: Mode = .onboarding, startStep: Int = 1, singleStep: Bool = false,
         onCancel: (() -> Void)? = nil, onFinish: @escaping () -> Void) {
        _child = child
        self.mode = mode
        self.singleStep = singleStep
        self.onCancel = onCancel
        self.onFinish = onFinish
        _step = State(initialValue: startStep)
        _original = State(initialValue: child.wrappedValue)
    }

    /// Editing the basics of an existing child: only continue to the subjects when the date of birth or the
    /// level changed, because the subjects depend on them. Otherwise "Save changes" saves and closes.
    private var isEditingBasics: Bool { mode == .editChild && !singleStep }

    private var basicsNeedSubjects: Bool {
        child.level != original.level || child.birthDate != original.birthDate
    }

    private var primaryTitle: String {
        if singleStep || step == 3 { return finishTitle }
        if isEditingBasics {
            return (step == 1 && basicsNeedSubjects) ? "Continue to subjects" : finishTitle
        }
        return "Continue"
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
        content.adaptiveColumn()
    }

    private var content: some View {
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
            } else if isEditingBasics {
                HStack {
                    if step > 1 {
                        Button { step -= 1 } label: { Label("Back", systemImage: "chevron.left") }
                            .foregroundStyle(Theme.obsidian)
                    } else if let onCancel {
                        Button("Cancel", action: onCancel)
                            .foregroundStyle(Theme.obsidian)
                    }
                    Spacer()
                    Text(step == 2 ? "Subjects" : "Details")
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
                Button(primaryTitle) {
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
        Label(hintText ?? subjectsNote ?? extraNote ?? "All set. Tap \(primaryTitle).",
              systemImage: (hintText != nil || subjectsNote != nil) ? "info.circle" : (extraNote != nil ? "plus.circle" : "checkmark.circle.fill"))
            .font(.footnote.weight(.medium))
            .foregroundStyle(hintColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Shown while editing when the date of birth or level changed.
    private var subjectsNote: String? {
        (isEditingBasics && step == 1 && basicsNeedSubjects)
            ? "Subjects depend on the level, so you’ll check them next."
            : nil
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
        if isEditingBasics {
            if step == 1, basicsNeedSubjects {
                // The level decides which subjects exist, so a new level means choosing them again.
                if child.level != original.level, subjectsClearedForLevel != child.level {
                    child.selectedSubjects = []
                    subjectsClearedForLevel = child.level
                }
                withAnimation { step = 2 }
            } else {
                // Just a name or other detail changed (or the subjects are done): save and close.
                onFinish()
            }
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
