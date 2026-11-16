import SwiftUI

/// A returning family's daily overview and subject cards share the saved plan with First Week and Progress.
struct ReturningHomeView: View {
    @Environment(AppState.self) private var state
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let child: Child
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var today = Calendar.current.startOfDay(for: .now)
    @State private var showAddChild = false
    @State private var showTaskEditor = false
    @State private var activeSubject: HomeSubjectSelection?
    @State private var completionFeedback = 0
    @State private var completingActivities: Set<WeekActivity.ID> = []
    @State private var undoFeedback = 0
    @State private var addedActivityID: WeekActivity.ID?
    @State private var showCompleted = false
    @State private var pendingCompletion: WeekActivity?
    @State private var pendingDeletion: WeekActivity?
    @State private var wrapUpRequest: DayLearningSummary?
    @State private var removedActivity: WeekActivity?
    @State private var removedIndex = 0

    private var plan: WeeklyPlan { state.weeklyPlans[child.id.uuidString] ?? .firstWeek(for: child) }
    private var selectedDay: String { plan.day(for: selectedDate) }
    private var isToday: Bool { Calendar.current.isDate(selectedDate, inSameDayAs: today) }
    private var activities: [WeekActivity] {
        plan.activities(on: selectedDay).filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    private var day: DayLearningProgress {
        DayLearningProgress(name: selectedDay, date: selectedDate, activities: activities)
    }
    private var homeTasks: [HomeLearningTask] {
        LearningProgress(plan: plan, selectedSubjects: child.subjectNames).homeTasks(on: selectedDate)
    }
    private var completedTasks: [HomeLearningTask] {
        homeTasks.filter { $0.activity.isDone && !completingActivities.contains($0.id) }
    }
    private var motion: Animation? { reduceMotion ? .easeOut(duration: 0.15) : .snappy(duration: 0.34, extraBounce: 0.02) }
    private var fullDay: String { selectedDate.formatted(.dateTime.weekday(.wide)) }
    private var completedFraction: Double {
        guard !activities.isEmpty else { return 0 }
        return Double(day.completed.count) / Double(activities.count)
    }
    private var todoSubtitle: String {
        if activities.isEmpty { return "A little space to follow their curiosity." }
        if day.isComplete { return "All done · a lovely little day of learning" }
        let encouragement = completedFraction >= 0.5 ? "you’re nearly there" : "one little step at a time"
        return "\(LearningProgress.duration(day.remainingMinutes)) left · \(encouragement)"
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HomePageHeader(dateText: today.formatted(.dateTime.weekday(.wide).month(.wide).day()),
                                   onAddChild: { showAddChild = true })
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your week")
                            .scaledFont(21, weight: .heavy, maxScale: 1.2).tracking(-0.4)
                            .accessibilityAddTraits(.isHeader)
                        weekCard
                    }
                    .padding(.top, 26)
                    todoHeading.padding(.top, Theme.Spacing.l)
                    checklist.padding(.top, Theme.Spacing.m)
                }
                .padding(.horizontal, TabPageLayout.horizontalInset)
                .padding(.top, TabPageLayout.topInset).padding(.bottom, 24)
                .frame(maxWidth: 650).frame(maxWidth: .infinity)
            }
            .scrollTitleBar("Home")
            .onChange(of: showTaskEditor) { _, showing in
                guard !showing, let addedActivityID else { return }
                withAnimation(motion) { scrollProxy.scrollTo(addedActivityID, anchor: .center) }
            }
        }
        .scrollIndicators(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showAddChild) { AddChildFlow() }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let removedActivity {
                ActivityRemovalNotice(activity: removedActivity, onUndo: undoRemoval)
                    .padding(.horizontal, 18).padding(.vertical, 8)
            }
        }
        .sheet(isPresented: $showTaskEditor) {
            WeekTaskSheet(activity: WeekActivity(date: selectedDate), week: plan,
                          isEditing: false) { activity in
                var updated = plan
                let previousIDs = Set(updated.activities.map(\.id))
                updated.add(activity)
                // WeeklyPlan.add creates new occurrence IDs, including a distinct ID for every repeated day.
                addedActivityID = updated.activities.first {
                    !previousIDs.contains($0.id) && Calendar.current.isDate($0.date, inSameDayAs: activity.date)
                }?.id
                state.saveWeek(updated, for: child.id)
                selectedDate = Calendar.current.startOfDay(for: activity.date)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .sheet(item: $activeSubject, onDismiss: {
            if let activity = pendingDeletion {
                pendingDeletion = nil
                delete(activity)
                return
            }
            guard let activity = pendingCompletion else { return }
            pendingCompletion = nil
            toggle(activity)
        }) { selection in
            HomeActivitySheet(activity: selection.activity,
                              onToggle: { pendingCompletion = selection.activity },
                              onDelete: { pendingDeletion = selection.activity })
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .onAppear(perform: refreshDay)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshDay() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in refreshDay() }
        .onChange(of: selectedDate) { _, _ in
            activeSubject = nil
            showCompleted = false
            wrapUpRequest = nil
            completingActivities.removeAll()
        }
        .onDisappear {
            completingActivities.removeAll()
            wrapUpRequest = nil
        }
        // Once every task for the day is ticked off, show the same "Learning, wrapped up." pop-up as the week page.
        .task(id: wrapUpRequest?.id) {
            guard let summary = wrapUpRequest else { return }
            do { try await Task.sleep(for: .milliseconds(reduceMotion ? 180 : 450)) }
            catch { return }
            guard !Task.isCancelled, selectedDay == summary.day, day.isComplete else { return }
            withAnimation(.easeOut(duration: 0.22)) { state.dailyWrapUp = summary }
            wrapUpRequest = nil
        }
        .sensoryFeedback(.success, trigger: completionFeedback)
        .sensoryFeedback(.selection, trigger: undoFeedback)
        .sensoryFeedback(.selection, trigger: selectedDate)
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(child.programmeText).scaledFont(14, weight: .medium, maxScale: 1.2)
                .lineLimit(1).minimumScaleFactor(0.75)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(Theme.surface, in: Capsule())
            if plan.days.isEmpty {
                Text("A little room to find your rhythm.").bodyText().padding(.vertical, 12)
            } else {
                rhythm
            }
            Text("\(plan.days.count) learning days")
                .scaledFont(11, maxScale: 1.25)
                .foregroundStyle(Theme.warmText)
                .frame(maxWidth: .infinity, alignment: .leading).frame(minHeight: 32)
            if !isToday {
                Button("Back to today") { withAnimation(motion) { selectedDate = today } }
                    .scaledFont(12, weight: .medium, maxScale: 1.2)
                    .foregroundStyle(Theme.warmText).buttonStyle(.plain)
                    .frame(maxWidth: .infinity, minHeight: 32)
                    .accessibilityIdentifier("home.backToToday")
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.pink, in: .rect(cornerRadius: 28))
        .overlay(alignment: .topTrailing) {
            HomeMascotIllustration()
                .frame(width: 128)
                .alignmentGuide(.top) { $0.height * HomeMascotIllustration.cardEdge }
                .offset(x: -6)
                .accessibilityHidden(true).allowsHitTesting(false)
        }
    }

    private var rhythm: some View {
        GeometryReader { geometry in
            let count = CGFloat(max(1, plan.days.count))
            let width = plan.days.count <= 4 ? min(82, max(48, (geometry.size.width - (count - 1) * 6 - 6) / count)) : 74
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(Array(plan.days.enumerated()), id: \.element) { index, name in
                            let date = plan.date(for: name)
                            let selected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                            Button { withAnimation(motion) { selectedDate = date } } label: {
                                VStack(spacing: 6) {
                                    Text(name.uppercased()).scaledFont(17, weight: .heavy, maxScale: 1.15)
                                    Capsule().fill(Color(hex: 0xF0959F)).frame(width: 22, height: 5)
                                    Text(LearningProgress.duration(plan.minutes(on: name)))
                                        .scaledFont(14, weight: .medium, maxScale: 1.2)
                                        .foregroundStyle(Theme.secondary).lineLimit(1).minimumScaleFactor(0.65)
                                }
                                .frame(width: width, height: 76)
                                .background(Theme.surface, in: .rect(cornerRadius: 14))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(selected ? HomePalette.coral.opacity(0.85) : .clear, lineWidth: 1.25)
                                }
                                .shadow(color: HomePalette.coral.opacity(selected ? 0.08 : 0), radius: 4, y: 2)
                                .rotationEffect(.degrees([-3, 2, -2, 3][index % 4]))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(date.formatted(.dateTime.weekday(.wide))), \(LearningProgress.duration(plan.minutes(on: name))) planned")
                            .accessibilityAddTraits(selected ? .isSelected : [])
                            .accessibilityIdentifier("home.day.\(name)")
                            .id(name)
                        }
                    }
                    .padding(.horizontal, 3).padding(.vertical, 7)
                }
                .scrollIndicators(.hidden)
                .onAppear { scrollProxy.scrollTo(selectedDay, anchor: .center) }
                .onChange(of: selectedDate) { _, _ in
                    withAnimation(motion) { scrollProxy.scrollTo(selectedDay, anchor: .center) }
                }
            }
        }
        .frame(height: 90)
    }

    private var todoHeading: some View {
        HStack(alignment: .center, spacing: 11) {
            completionRing
            VStack(alignment: .leading, spacing: 3) {
                Text(isToday ? "Today’s to-dos" : "\(fullDay)’s to-dos")
                    .scaledFont(22, weight: .heavy, maxScale: 1.2).tracking(-0.6)
                    .accessibilityAddTraits(.isHeader)
                Text(todoSubtitle)
                    .scaledFont(12, maxScale: 1.3).foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true).contentTransition(.numericText())
            }
            Spacer(minLength: 0)
            Button { showTaskEditor = true } label: {
                Image(systemName: "plus").font(.system(size: 24, weight: .medium))
                    .foregroundStyle(HomePalette.plusInk)
                    .frame(width: 52, height: 52)
                    .background(HomePalette.plusFill, in: Circle())
                    .overlay(Circle().strokeBorder(HomePalette.plusRing, lineWidth: 2))
                    .shadow(color: HomePalette.plusInk.opacity(0.10), radius: 6, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add a learning activity")
            .accessibilityIdentifier("home.addActivity")
        }
    }

    private var completionRing: some View {
        ZStack {
            Circle().strokeBorder(HomePalette.taskAccent.opacity(0.15), lineWidth: 5)
            Circle().trim(from: 0, to: completedFraction)
                .stroke(HomePalette.taskAccent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90)).padding(2.5)
            Text("\(day.completed.count)/\(activities.count)")
                .scaledFont(13, weight: .bold, maxScale: 1.2).monospacedDigit()
                .minimumScaleFactor(0.6).lineLimit(1).padding(7)
                .contentTransition(.numericText())
        }
        .frame(width: 48, height: 48)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(day.completed.count) of \(activities.count) activities complete")
    }

    private var checklist: some View {
        VStack(alignment: .leading, spacing: 16) {
            if homeTasks.isEmpty {
                Text("Nothing planned for \(isToday ? "today" : fullDay.lowercased()). Add an idea whenever you’re ready.")
                    .bodyText().foregroundStyle(Theme.secondary)
                    .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .background(HomePalette.taskSurface, in: .rect(cornerRadius: 22))
            } else {
                ForEach(homeTasks.filter { !$0.activity.isDone || completingActivities.contains($0.id) }) { task in
                    let completing = completingActivities.contains(task.id)
                    subjectCard(task).id(task.id)
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.96))))
                        .task(id: completing) {
                            guard completing else { return }
                            // Let the tick draw before removal; this task is cancelled when its row leaves Home.
                            do { try await Task.sleep(for: .milliseconds(reduceMotion ? 180 : 280)) }
                            catch { return }
                            guard !Task.isCancelled, completingActivities.contains(task.id) else { return }
                            withAnimation(motion) { completingActivities.remove(task.id) }
                            if completingActivities.isEmpty { requestWrapUpIfFinished(in: plan) }
                        }
                }
                if !completedTasks.isEmpty {
                    Button {
                        withAnimation(motion) { showCompleted.toggle() }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Completed · \(completedTasks.count)").cardTitle()
                            Spacer()
                            Image(systemName: "chevron.down").rotationEffect(.degrees(showCompleted ? 180 : 0))
                        }
                        .foregroundStyle(Theme.secondary).frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.completed")
                    .accessibilityValue(showCompleted ? "Expanded" : "Collapsed")
                    if showCompleted {
                        ForEach(completedTasks) { task in
                            subjectCard(task).id(task.id).opacity(0.75)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
            }
        }
    }

    /// A plain to-do row inside the subject's coloured box: tick on the left, topic name beside it.
    /// Tapping the tick completes the task; tapping the box opens its description.
    private func subjectCard(_ task: HomeLearningTask) -> some View {
        let index = task.subjectIndex
        let palette = SubjectCardPalette.all[index % SubjectCardPalette.all.count]
        let finished = task.activity.isDone
        let completing = completingActivities.contains(task.id)
        let tickMotion: Animation = reduceMotion ? .easeOut(duration: 0.15) : .smooth(duration: 0.2)
        return HStack(spacing: 8) {
            Button { toggle(task.activity) } label: {
                // Both symbols share a fixed box, so the check never changes the button's layout or position.
                ZStack {
                    Image(systemName: "circle").opacity(finished ? 0 : 1)
                    Image(systemName: "checkmark.circle.fill")
                        .opacity(finished ? 1 : 0)
                        .scaleEffect(finished || reduceMotion ? 1 : 0.65)
                }
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(palette.ink)
                .frame(width: 28, height: 28)
                .animation(tickMotion, value: finished)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(completing)
            .accessibilityLabel(finished ? "Mark \(task.activity.title) not complete" : "Mark \(task.activity.title) complete")
            .accessibilityIdentifier("home.tick.\(task.id)")

            Button {
                activeSubject = HomeSubjectSelection(activity: task.activity)
            } label: {
                Text(task.activity.title)
                    .scaledFont(18, weight: .semibold, maxScale: 1.25)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 18)
                    .frame(minHeight: 72)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HomeSubjectPressStyle(reduceMotion: reduceMotion))
            .disabled(completing)
            .accessibilityLabel("\(task.activity.title), \(task.subjectName)")
            .accessibilityValue(finished ? "Completed" : "Not complete")
            .accessibilityHint("Open the task description")
            .accessibilityIdentifier("home.activity.\(task.id)")
        }
        .padding(.leading, 12).padding(.trailing, 18)
        .background {
            ZStack(alignment: .trailing) {
                palette.paper
                Image(systemName: SubjectCardPalette.symbol(for: task.subjectName))
                    .font(.system(size: 62, weight: .ultraLight))
                    .foregroundStyle(palette.ink.opacity(0.08))
                    .rotationEffect(.degrees(-15))
                    .padding(.trailing, 16)
                    .accessibilityHidden(true)
            }
            .clipShape(RoundedRectangle(cornerRadius: 27))
        }
        .overlay(RoundedRectangle(cornerRadius: 27).strokeBorder(Theme.surface.opacity(0.9), lineWidth: 1.5))
        .shadow(color: palette.ink.opacity(0.06), radius: 6, y: 3)
        .rotationEffect(.degrees(reduceMotion ? 0 : (index.isMultiple(of: 2) ? -0.6 : 0.6)))
        .padding(.horizontal, 3)
    }

    private func toggle(_ activity: WeekActivity) {
        guard !completingActivities.contains(activity.id) else { return }
        var updated = plan
        guard let index = updated.activities.firstIndex(where: { $0.id == activity.id }) else { return }
        let completing = !updated.activities[index].isDone
        wrapUpRequest = nil
        if completing {
            // Keep saving outside the tick's animation transaction so page labels do not morph into the task row.
            completingActivities.insert(activity.id)
            updated.activities[index].setCompleted(true)
            state.saveWeek(updated, for: child.id)
            completionFeedback += 1
        } else {
            withAnimation(motion) {
                updated.activities[index].setCompleted(false)
                state.saveWeek(updated, for: child.id)
                undoFeedback += 1
            }
        }
    }

    /// Removes just this day's occurrence of the task. Repeats on other days stay.
    private func delete(_ activity: WeekActivity) {
        var updated = plan
        guard let index = updated.activities.firstIndex(where: { $0.id == activity.id }),
              let removed = updated.removeForDay(activity.id) else { return }
        withAnimation(motion) {
            removedIndex = index
            removedActivity = removed
            state.saveWeek(updated, for: child.id)
            wrapUpRequest = nil
            undoFeedback += 1
        }
    }

    private func undoRemoval() {
        guard let removedActivity, !plan.activities.contains(where: { $0.id == removedActivity.id }) else { return }
        var updated = plan
        updated.activities.insert(removedActivity, at: min(removedIndex, updated.activities.count))
        withAnimation(motion) {
            state.saveWeek(updated, for: child.id)
            selectedDate = Calendar.current.startOfDay(for: removedActivity.date)
            self.removedActivity = nil
            wrapUpRequest = nil
            undoFeedback += 1
        }
    }

    /// Same rule as the week page: show the wrap-up once nothing is left to do and something was completed.
    private func requestWrapUpIfFinished(in updated: WeeklyPlan) {
        let dayTasks = updated.activities(on: selectedDay).filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
        guard !dayTasks.isEmpty, dayTasks.allSatisfy(\.isDone) else { return }
        wrapUpRequest = updated.learningSummary(on: selectedDay, childName: child.displayName)
    }

    private func refreshDay() {
        let newToday = Calendar.current.startOfDay(for: .now)
        if today != newToday { today = newToday; selectedDate = newToday }
        state.prepareHomeWeek(for: child.id, today: newToday)
    }
}

private struct HomeSubjectSelection: Identifiable {
    let activity: WeekActivity
    var id: WeekActivity.ID { activity.id }
}

private struct HomeSubjectPressStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private enum HomePalette {
    // Match the soft lavender surface and deeper purple text used by Progress.
    static let taskSurface = Color(hex: 0xE6DEFF)
    static let taskAccent = Color(hex: 0x4430A5)
    static let ink = Color(hex: 0x1B1D1C)
    static let onInk = Color(hex: 0xFFFFFF)
    static let coral = Color(hex: 0xB46759)
    // Add-activity button: soft lavender disc, white ring, deep navy plus.
    static let plusFill = Color(hex: 0xE6E0FF)
    static let plusInk = Color(hex: 0x2B2559)
    static let plusRing = Color(hex: 0xFFFFFF)
}
