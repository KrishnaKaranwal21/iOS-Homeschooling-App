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
    @State private var undoFeedback = 0
    @State private var addedActivityID: WeekActivity.ID?
    @State private var showCompleted = false
    @State private var pendingCompletion: WeekActivity?
    @State private var pendingDeletion: WeekActivity?
    @State private var wrapUpRequest: DayLearningSummary?

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
                    topRow
                    Text("A little learning.\nA lighter day.")
                        .pageTitle().lineSpacing(-3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 12)
                    weekCard.padding(.top, 26)
                    todoHeading.padding(.top, 26)
                    checklist.padding(.top, 16)
                }
                .padding(.horizontal, 18).padding(.top, 6).padding(.bottom, 24)
                .frame(maxWidth: 650).frame(maxWidth: .infinity)
            }
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

    private var topRow: some View {
        HStack(spacing: 10) {
            Text(today.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .scaledFont(14, maxScale: 1.3).foregroundStyle(Theme.secondary)
                .lineLimit(1).minimumScaleFactor(0.75)
            Spacer(minLength: 4)
            ChildSwitcherMenu(onAddChild: { showAddChild = true }) {
                HStack(spacing: 7) {
                    AvatarView(initials: String(child.displayName.prefix(1)).uppercased(), color: Theme.lavender, size: 26)
                    Text(child.displayName).scaledFont(15, weight: .medium, maxScale: 1.3).lineLimit(1)
                    Image(systemName: "chevron.down").font(.system(size: 11, weight: .bold))
                }
                .padding(.leading, 5).padding(.trailing, 12).frame(height: 36)
                .gatherGlass(in: Capsule(), tint: Theme.lilac)
            }
            NavigationLink { ProfileView() } label: {
                Image(systemName: "person").font(.system(size: 17, weight: .medium))
                    .frame(width: 36, height: 36).gatherGlass(in: Circle(), tint: Theme.lilac)
            }
            .accessibilityLabel("Profile")
        }
        .buttonStyle(.plain).frame(minHeight: 44)
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR WEEK").scaledFont(11, weight: .medium, maxScale: 1.2)
                .tracking(0.5).foregroundStyle(Theme.warmText)
            Text(child.programmeText).scaledFont(14, weight: .medium, maxScale: 1.2)
                .lineLimit(1).minimumScaleFactor(0.75)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(Theme.surface, in: Capsule())
            Text("Your chosen rhythm")
                .scaledFont(21, weight: .heavy, maxScale: 1.2).tracking(-0.4)
                .padding(.top, 2)
            if plan.days.isEmpty {
                Text("A little room to find your rhythm.").bodyText().padding(.vertical, 12)
            } else {
                rhythm
            }
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
            HomeMascotView().frame(width: 116).offset(x: 3, y: -54)
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
                ForEach(homeTasks.filter { !$0.activity.isDone }) { task in
                    subjectCard(task).id(task.id)
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.96))))
                }
                if !day.completed.isEmpty {
                    Button {
                        withAnimation(motion) { showCompleted.toggle() }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Completed · \(day.completed.count)").cardTitle()
                            Spacer()
                            Image(systemName: "chevron.down").rotationEffect(.degrees(showCompleted ? 180 : 0))
                        }
                        .foregroundStyle(Theme.secondary).frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.completed")
                    .accessibilityValue(showCompleted ? "Expanded" : "Collapsed")
                    if showCompleted {
                        ForEach(homeTasks.filter { $0.activity.isDone }) { task in
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
        return ZStack(alignment: .leading) {
            Button {
                activeSubject = HomeSubjectSelection(activity: task.activity)
            } label: {
                Text(task.activity.title)
                    .scaledFont(18, weight: .semibold, maxScale: 1.25)
                    .foregroundStyle(finished ? Theme.secondary : Theme.ink)
                    .strikethrough(finished)
                    .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 64).padding(.trailing, 18).padding(.vertical, 18)
                    .frame(minHeight: 72)
                    .background {
                        ZStack(alignment: .trailing) {
                            palette.paper
                            // The subject's own symbol (flask for Science, paintpalette for Art...) sits faintly behind the task.
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
                    .contentShape(RoundedRectangle(cornerRadius: 27))
            }
            .buttonStyle(HomeSubjectPressStyle(reduceMotion: reduceMotion))
            .accessibilityLabel("\(task.activity.title), \(task.subjectName)")
            .accessibilityValue(finished ? "Completed" : "Not complete")
            .accessibilityHint("Open the task description")
            .accessibilityIdentifier("home.activity.\(task.id)")

            Button { toggle(task.activity) } label: {
                Image(systemName: finished ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(palette.ink)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 12)
            .accessibilityLabel(finished ? "Mark \(task.activity.title) not complete" : "Mark \(task.activity.title) complete")
            .accessibilityIdentifier("home.tick.\(task.id)")
        }
        .padding(.horizontal, 3)
    }

    private func toggle(_ activity: WeekActivity) {
        var updated = plan
        guard let index = updated.activities.firstIndex(where: { $0.id == activity.id }) else { return }
        let completing = !updated.activities[index].isDone
        withAnimation(motion) {
            updated.activities[index].isDone = completing
            state.saveWeek(updated, for: child.id)
            if completing { completionFeedback += 1 }
            else { undoFeedback += 1 }
        }
        if completing { requestWrapUpIfFinished(in: updated) } else { wrapUpRequest = nil }
    }

    /// Removes just this day's occurrence of the task. Repeats on other days stay.
    private func delete(_ activity: WeekActivity) {
        var updated = plan
        guard updated.removeForDay(activity.id) != nil else { return }
        withAnimation(motion) { state.saveWeek(updated, for: child.id) }
        requestWrapUpIfFinished(in: updated)
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
    static let taskSurface = Color.adaptive(0xE6DEFF, 0x292338)
    static let taskAccent = Color.adaptive(0x4430A5, 0xBBA4FF)
    static let ink = Color.adaptive(0x1B1D1C, 0xF5F5F7)
    static let onInk = Color.adaptive(0xFFFFFF, 0x1B1D1C)
    static let coral = Color.adaptive(0xB46759, 0xF0ADAA)
    // Add-activity button: soft lavender disc, white ring, deep navy plus.
    static let plusFill = Color.adaptive(0xE6E0FF, 0x3B3059)
    static let plusInk = Color.adaptive(0x2B2559, 0xE6E0FF)
    static let plusRing = Color.adaptive(0xFFFFFF, 0x4A4060)
}
