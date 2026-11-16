import SwiftUI

/// Keeps the Home tab bar visible while the family reviews their first week.
struct FirstWeekView: View {
    var initialDay: String? = nil
    var backTitle = "Home"
    @Environment(AppState.self) private var state
    @State private var showAddChild = false

    var body: some View {
        WeekPlanPage(child: state.child, savedPlan: state.weeklyPlans[state.child.id.uuidString],
                     initialDay: initialDay, backTitle: backTitle, onAddChild: { showAddChild = true })
            .id(state.child.id)
            .fullScreenCover(isPresented: $showAddChild) { AddChildFlow() }
    }
}

/// The shared native planner opens from Home and Progress while the first-week preview remains available during setup.
struct DayPlannerSheet: View {
    @Environment(AppState.self) private var state
    var initialDay: String? = nil
    var onSelectDate: (Date) -> Void = { _ in }

    var body: some View {
        WeekPlanPage(child: state.child, savedPlan: state.weeklyPlans[state.child.id.uuidString],
                     initialDay: initialDay, backTitle: "", onAddChild: {},
                     isSheet: true, onSelectDate: onSelectDate)
            .id(state.child.id)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
    }
}

private struct WeekPlanPage: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let child: Child
    let backTitle: String
    let onAddChild: () -> Void
    let isSheet: Bool
    let onSelectDate: (Date) -> Void
    @State private var plan: WeeklyPlan
    @State private var selectedDay: String
    private struct TaskEditorRequest: Identifiable {
        let id = UUID()
        let activity: WeekActivity
        let isEditing: Bool
    }
    @State private var taskEditor: TaskEditorRequest?
    @State private var showTimes = false
    @State private var saved = false
    @State private var showCompleted = false
    @State private var removedActivity: WeekActivity?
    @State private var removedIndex = 0
    @State private var completionFeedback = 0
    @State private var wrapUpRequest: DayLearningSummary?

    init(child: Child, savedPlan: WeeklyPlan?, initialDay: String?, backTitle: String, onAddChild: @escaping () -> Void,
         isSheet: Bool = false, onSelectDate: @escaping (Date) -> Void = { _ in }) {
        self.child = child
        self.backTitle = backTitle
        self.onAddChild = onAddChild
        self.isSheet = isSheet
        self.onSelectDate = onSelectDate
        let plan = savedPlan ?? .firstWeek(for: child)
        _plan = State(initialValue: plan)
        _selectedDay = State(initialValue: initialDay.flatMap { WeeklyPlan.dayNames.contains($0) ? $0 : nil } ?? plan.days.first ?? "Mon")
        _saved = State(initialValue: savedPlan != nil)
    }

    private var dayIndex: Int { WeeklyPlan.dayNames.firstIndex(of: selectedDay) ?? 0 }
    private var dailyMinutes: Int { plan.minutes(on: selectedDay) }
    private var remaining: [WeekActivity] { plan.remainingActivities(on: selectedDay) }
    private var completed: [WeekActivity] { plan.completedActivities(on: selectedDay) }
    private var rowAnimation: Animation { reduceMotion ? .easeOut(duration: 0.18) : .spring(response: 0.38, dampingFraction: 0.88) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if isSheet {
                    plannerHeader
                    plannerIntro
                    rhythm.padding(12)
                        .background(Theme.pink.opacity(0.65), in: .rect(cornerRadius: 24))
                } else {
                header
                Text("YOUR WEEK")
                    .scaledFont(11, weight: .semibold, maxScale: 1.2)
                    .foregroundStyle(Color.adaptive(0x8D4540, 0xF2ABA3))
                    .padding(.horizontal, 15).padding(.vertical, 6)
                    .background(WeekStyle.pink, in: Capsule())

                Text("A week, shaped\naround \(child.displayName).")
                    .pageTitle()
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(child.programmeText).scaledFont(16, weight: .semibold, maxScale: 1.2)
                    Text("\(plan.days.count) days · \(LearningProgress.duration(plan.plannedMinutes)) planned")
                        .scaledFont(14, maxScale: 1.3)
                        .foregroundStyle(WeekStyle.secondary)
                }
                .padding(.horizontal, 18).padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(WeekStyle.lavender, in: .rect(cornerRadius: 16))

                Text("Your chosen rhythm").sectionTitle()
                rhythm
                }
                dayHeading

                if remaining.isEmpty { dayEmptyState }
                VStack(spacing: 8) {
                    ForEach(remaining) { activity in
                        activityRow(activity)
                            .transition(reduceMotion ? .opacity : .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.96))))
                    }
                }
                if !completed.isEmpty { completedSection }
                if dailyMinutes > plan.hoursPerDay * 60 {
                    Text("This day is \(dailyMinutes - plan.hoursPerDay * 60) min over your chosen rhythm. Adjust a task to make a little more room.")
                        .caption().foregroundStyle(Color.adaptive(0x9C4A4B, 0xF0ADAA))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, isSheet ? 22 : 8)
            .padding(.bottom, 8)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background)
        .foregroundStyle(Theme.ink)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .sheet(item: $taskEditor) { request in
            WeekTaskSheet(activity: request.activity, week: plan, isEditing: request.isEditing) { activity in
                if let index = plan.activities.firstIndex(where: { $0.id == activity.id }), request.isEditing {
                    plan.activities[index] = activity
                    let day = plan.day(for: activity.date)
                    if !plan.days.contains(day) {
                        plan.days = WeeklyPlan.dayNames.filter { plan.days.contains($0) || $0 == day }
                    }
                } else {
                    plan.add(activity)
                }
                selectedDay = plan.day(for: activity.date)
            }
            .presentationDetents(isSheet ? [.large] : [.fraction(0.82), .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showTimes) {
            DayStartTimeSheet(day: WeeklyPlan.fullDayNames[dayIndex],
                              initialTime: plan.startTimes[selectedDay]) { time in
                plan.startTimes[selectedDay] = time
            }
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.visible)
        }
        // The plan can change outside this page (for example, when the child's days, hours or subjects are edited).
        .onChange(of: state.weeklyPlans[child.id.uuidString]) { _, latest in
            guard let latest, latest != plan else { return }
            plan = latest
            if !plan.days.contains(selectedDay), let first = plan.days.first { selectedDay = first }
        }
        .onChange(of: plan) { _, _ in
            state.saveWeek(plan, for: child.id)
            saved = true
            if !remaining.isEmpty { wrapUpRequest = nil }
        }
        .onAppear {
            state.saveWeek(plan, for: child.id)
            saved = true
        }
        .onChange(of: selectedDay) { _, _ in
            wrapUpRequest = nil
            showCompleted = false
            onSelectDate(plan.date(for: selectedDay))
        }
        .task(id: wrapUpRequest?.id) {
            guard let summary = wrapUpRequest else { return }
            do { try await Task.sleep(for: .milliseconds(reduceMotion ? 180 : 450)) }
            catch { return }
            guard !Task.isCancelled, selectedDay == summary.day, remaining.isEmpty else { return }
            withAnimation(.easeOut(duration: 0.22)) { state.dailyWrapUp = summary }
        }
        .sensoryFeedback(.success, trigger: completionFeedback)
        .sensoryFeedback(.selection, trigger: selectedDay)
    }

    private var plannerHeader: some View {
        HStack(spacing: 12) {
            Label("PLAN YOUR DAY", systemImage: "pencil.and.outline")
                .scaledFont(11, weight: .semibold, maxScale: 1.25)
                .tracking(1).foregroundStyle(WeekStyle.purple)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 16, weight: .medium))
                    .frame(width: 44, height: 44)
                    .gatherGlass(in: Circle(), tint: Theme.lilac.opacity(0.4))
            }
            .buttonStyle(.plain).accessibilityLabel("Close day planner")
        }
    }

    private var plannerIntro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(WeeklyPlan.fullDayNames[dayIndex]),\nyour way.")
                .scaledFont(32, weight: .heavy, maxScale: 1.2).tracking(-1)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 6) {
                Text(child.displayName)
                Text("·")
                Text(plan.date(for: selectedDay).formatted(.dateTime.day().month(.abbreviated)))
                Spacer(minLength: 0)
                Label(LearningProgress.duration(dailyMinutes), systemImage: "clock")
                    .foregroundStyle(WeekStyle.purple)
            }
            .scaledFont(13, weight: .medium, maxScale: 1.25).foregroundStyle(Theme.secondary)
        }
        .padding(.bottom, 8)
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Label(backTitle, systemImage: "chevron.left")
                    .scaledFont(16, weight: .semibold, maxScale: 1.2)
                    .foregroundStyle(WeekStyle.secondary)
                    .frame(minHeight: 44)
            }
            Spacer()
            ChildSwitcherMenu(onAddChild: onAddChild) {
                HStack(spacing: 8) {
                    AvatarView(initials: String(child.displayName.prefix(1)).uppercased(), color: Theme.lavender, size: 26)
                    Text(child.displayName).scaledFont(15, weight: .medium, maxScale: 1.2).lineLimit(1)
                    Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold))
                }
                .padding(.leading, 6).padding(.trailing, 12).padding(.vertical, 6)
                .background(WeekStyle.field, in: Capsule())
            }
        }
        .buttonStyle(.plain)
    }

    private var rhythm: some View {
        ScrollViewReader { proxy in
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(Array(plan.days.enumerated()), id: \.element) { index, day in
                    Button { selectedDay = day } label: {
                        VStack(spacing: 5) {
                            Text(day.uppercased()).scaledFont(18, weight: .heavy, maxScale: 1.2)
                            Capsule().fill(Color(hex: 0xFF8D9A)).frame(width: 25, height: 6)
                            Text(LearningProgress.duration(plan.minutes(on: day)))
                                .scaledFont(16, weight: .medium, maxScale: 1.2)
                                .foregroundStyle(WeekStyle.secondary)
                        }
                        .frame(width: 79, height: 76)
                        .background(selectedDay == day ? Theme.surface : WeekStyle.pink, in: .rect(cornerRadius: 9))
                        .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(selectedDay == day ? WeekStyle.purple : .clear, lineWidth: 1))
                        .rotationEffect(.degrees([-5, 5, -5, 5][index % 4]))
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(WeeklyPlan.fullDayNames[WeeklyPlan.dayNames.firstIndex(of: day)!]), \(LearningProgress.duration(plan.minutes(on: day))) planned")
                    .accessibilityAddTraits(day == selectedDay ? .isSelected : [])
                    .id(day)
                }
                AddLearningDayButton(days: plan.days) { day in
                    guard let date = state.addLearningDay(day, for: child.id),
                          let updated = state.weeklyPlans[child.id.uuidString] else { return }
                    plan = updated
                    selectedDay = plan.day(for: date)
                }
            }
            .padding(.horizontal, 5)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.trailing, 5)
        .padding(.horizontal, -5)
        .onAppear { proxy.scrollTo(selectedDay, anchor: .center) }
        .onChange(of: selectedDay) { _, day in
            withAnimation(reduceMotion ? nil : rowAnimation) { proxy.scrollTo(day, anchor: .center) }
        }
        }
    }

    private var dayHeading: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(isSheet ? "Your activities" : WeeklyPlan.fullDayNames[dayIndex]).sectionTitle()
                Spacer()
                Button { showTimes = true } label: {
                    Label(plan.startTimes[selectedDay] == nil ? "Set times" : "Edit times", systemImage: "clock")
                        .scaledFont(13, weight: .medium, maxScale: 1.2)
                        .foregroundStyle(WeekStyle.secondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }
            Text(Self.duration(dailyMinutes) + " learning" + (completed.isEmpty ? "" : " · \(remaining.count) left"))
                .scaledFont(14, maxScale: 1.2).foregroundStyle(WeekStyle.secondary)
        }
    }

    private func activityRow(_ activity: WeekActivity) -> some View {
        let subjectIndex = child.subjectNames.firstIndex { LearningProgress.subjectKey($0) == LearningProgress.subjectKey(activity.subject) } ?? 0
        let palette = SubjectCardPalette.all[subjectIndex % SubjectCardPalette.all.count]
        return HStack(spacing: 0) {
            Button {
                taskEditor = TaskEditorRequest(activity: activity, isEditing: true)
            } label: {
                HStack(spacing: 10) {
                    Text("\(activity.minutes) min")
                        .scaledFont(14, weight: .medium, maxScale: 1.2)
                        .foregroundStyle(activity.subject.lowercased().contains("math") ? Color.adaptive(0x8D4540, 0xF2ABA3) : WeekStyle.purple)
                        .frame(width: 62, height: 32)
                        .background(activity.subject.lowercased().contains("math") ? WeekStyle.pink : Theme.field, in: Capsule())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activity.subject.uppercased())
                            .scaledFont(9, weight: .medium, maxScale: 1.3).foregroundStyle(WeekStyle.secondary)
                        Text(activity.title).scaledFont(15, weight: .semibold, maxScale: 1.25)
                            .strikethrough(activity.isDone)
                            .multilineTextAlignment(.leading)
                        if let time = scheduledTime(for: activity) {
                            Text(time.formatted(date: .omitted, time: .shortened))
                                .scaledFont(11, maxScale: 1.2).foregroundStyle(WeekStyle.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Edit task")

            if isSheet {
                Menu {
                    Button { taskEditor = TaskEditorRequest(activity: activity, isEditing: true) } label: {
                        Label("Edit activity", systemImage: "pencil")
                    }
                    Button(role: .destructive) { remove(activity) } label: {
                        Label("Remove from this day", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis").font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(palette.ink).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Options for \(activity.title)")
            } else {
            Button { complete(activity) } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(WeekStyle.purple)
                    .frame(width: 30, height: 30)
                    .background(WeekStyle.field, in: Circle())
                    .overlay(Circle().strokeBorder(Color.adaptive(0xB5A9DA, 0x8F7DAE), lineWidth: 1))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Complete \(activity.title)")
            .accessibilityIdentifier("week.complete.\(activity.id)")

            Button { remove(activity) } label: {
                Image(systemName: "minus.circle")
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(Color.adaptive(0x9C6C73, 0xD7A1AE))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(activity.title) for this day")
            .accessibilityHint("Other days stay the same. You can undo this removal.")
            }
        }
        .padding(.leading, isSheet ? 14 : 11).padding(.trailing, 5).padding(.vertical, isSheet ? 12 : 3)
        .frame(minHeight: 52)
        .background(isSheet ? palette.paper : Theme.surface, in: .rect(cornerRadius: isSheet ? 20 : 11))
        .overlay(RoundedRectangle(cornerRadius: isSheet ? 20 : 11).strokeBorder(isSheet ? Theme.surface : WeekStyle.border, lineWidth: 0.8))
    }

    private var footer: some View {
        VStack(spacing: 8) {
            if let removedActivity {
                HStack(spacing: 10) {
                    Image(systemName: "minus.circle.fill").foregroundStyle(WeekStyle.secondary)
                    Text("Removed for \(WeeklyPlan.fullDayNames[WeeklyPlan.dayNames.firstIndex(of: plan.day(for: removedActivity.date))!])")
                        .scaledFont(12, weight: .medium, maxScale: 1.2)
                    Spacer(minLength: 0)
                    Button("Undo", action: undoRemoval)
                        .scaledFont(13, weight: .semibold, maxScale: 1.2)
                        .foregroundStyle(WeekStyle.purple)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.horizontal, 12)
                .background(WeekStyle.field, in: .rect(cornerRadius: 14))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if isSheet {
                Button {
                    taskEditor = TaskEditorRequest(activity: WeekActivity(date: plan.date(for: selectedDay)), isEditing: false)
                } label: {
                    Label("Add an activity", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primaryHomeschool)
                .accessibilityIdentifier("planner.addActivity")
            } else {
            HStack {
                Spacer()
                Button {
                    taskEditor = TaskEditorRequest(activity: WeekActivity(date: plan.date(for: selectedDay)), isEditing: false)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(WeekStyle.purple)
                        .frame(width: 52, height: 52)
                        .background(WeekStyle.lavender, in: Circle())
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                        .shadow(color: WeekStyle.purple.opacity(0.13), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add activity")
                .accessibilityIdentifier("week.addActivity")
            }
            Button {
                state.saveWeek(plan, for: child.id)
                saved = true
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    if saved { Image(systemName: "checkmark") }
                    Text("Done")
                }
                    .scaledFont(16, weight: .semibold, maxScale: 1.2)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .background(Theme.buttonFill, in: Capsule())
            }
            .buttonStyle(.plain)
            }
            Text("Changes save automatically. Adjust anytime.")
                .scaledFont(11, maxScale: 1.2).foregroundStyle(WeekStyle.secondary)
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 10)
        .background(LinearGradient(colors: [Theme.background.opacity(0), Theme.background, Theme.background], startPoint: .top, endPoint: .bottom))
    }

    private var dayEmptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: completed.isEmpty ? "leaf" : "checkmark.seal.fill")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(WeekStyle.purple)
                .frame(width: 62, height: 62)
                .background(WeekStyle.lavender, in: Circle())
            Text(completed.isEmpty ? "A little breathing room." : "Learning, wrapped up.")
                .scaledFont(20, weight: .bold, maxScale: 1.2)
            Text(completed.isEmpty ? "Tap + whenever you’re ready to add something." : "You’ve made room for the rest of your day.")
                .caption().multilineTextAlignment(.center)
            if !completed.isEmpty {
                Button("View today’s summary") {
                    withAnimation(.easeOut(duration: 0.2)) {
                        state.dailyWrapUp = plan.learningSummary(on: selectedDay, childName: child.displayName)
                    }
                }
                .scaledFont(13, weight: .semibold, maxScale: 1.2)
                .foregroundStyle(WeekStyle.purple).frame(minHeight: 44)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: .rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(WeekStyle.border, lineWidth: 0.8))
        .transition(.opacity)
    }

    private var completedSection: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(rowAnimation) { showCompleted.toggle() }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark.seal")
                    Text("\(completed.count) completed · \(completed.reduce(0) { $0 + $1.minutes }) min logged")
                        .scaledFont(12, weight: .medium, maxScale: 1.2)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .rotationEffect(.degrees(showCompleted ? 180 : 0))
                }
                .foregroundStyle(WeekStyle.secondary).frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(showCompleted ? "Expanded" : "Collapsed")
            if showCompleted {
                ForEach(completed) { activity in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(WeekStyle.secondary)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(activity.title).scaledFont(14, weight: .medium, maxScale: 1.2)
                            Text("\(activity.minutes) min · \(activity.subject)").caption()
                        }
                        Spacer(minLength: 0)
                        Button {
                            withAnimation(rowAnimation) {
                                if let index = plan.activities.firstIndex(where: { $0.id == activity.id }) {
                                    plan.activities[index].setCompleted(false)
                                    wrapUpRequest = nil
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .foregroundStyle(WeekStyle.purple).frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Undo completion of \(activity.title)")
                    }
                    .padding(.leading, 12).padding(.vertical, 4)
                    .background(WeekStyle.field.opacity(0.6), in: .rect(cornerRadius: 12))
                    .transition(.opacity)
                }
            }
        }
    }

    private func complete(_ activity: WeekActivity) {
        withAnimation(rowAnimation) {
            guard plan.complete(activity.id) else { return }
            completionFeedback += 1
            requestWrapUpIfFinished()
        }
    }

    private func remove(_ activity: WeekActivity) {
        guard let index = plan.activities.firstIndex(where: { $0.id == activity.id }) else { return }
        withAnimation(rowAnimation) {
            removedIndex = index
            removedActivity = plan.removeForDay(activity.id)
            if isSheet { wrapUpRequest = nil } else { requestWrapUpIfFinished() }
        }
    }

    private func undoRemoval() {
        guard let activity = removedActivity else { return }
        withAnimation(rowAnimation) {
            plan.activities.insert(activity, at: min(removedIndex, plan.activities.count))
            removedActivity = nil
            wrapUpRequest = nil
            selectedDay = plan.day(for: activity.date)
        }
    }

    private func requestWrapUpIfFinished() {
        // An empty or entirely removed day is not a completed learning day.
        guard remaining.isEmpty, !completed.isEmpty else { return }
        wrapUpRequest = plan.learningSummary(on: selectedDay, childName: child.displayName)
    }

    private func scheduledTime(for activity: WeekActivity) -> Date? {
        if let time = activity.time { return time }
        guard let start = plan.startTimes[selectedDay] else { return nil }
        let preceding = plan.activities(on: selectedDay).prefix { $0.id != activity.id }
        return Calendar.current.date(byAdding: .minute, value: preceding.reduce(0) { $0 + $1.minutes }, to: start)
    }

    static func duration(_ minutes: Int) -> String {
        if minutes % 60 == 0 { return "\(minutes / 60)h" }
        if minutes < 60 { return "\(minutes) min" }
        return "\(minutes / 60)h \(minutes % 60) min"
    }
}

enum WeekStyle {
    static let pink = Color.adaptive(0xFFC4C8, 0x482D38)
    static let lavender = Color.adaptive(0xE9E5FF, 0x30283F)
    static let field = Color.adaptive(0xF4F2FF, 0x24212D)
    static let secondary = Color.adaptive(0x817D9F, 0xAEA6C3)
    static let purple = Color.adaptive(0x2B2859, 0xD4C8F4)
    static let border = Color.adaptive(0xDFDDED, 0x40384F)
}

private struct DayStartTimeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let day: String
    let onSave: (Date?) -> Void
    @State private var time: Date

    init(day: String, initialTime: Date?, onSave: @escaping (Date?) -> Void) {
        self.day = day
        self.onSave = onSave
        _time = State(initialValue: initialTime ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now)!)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("\(day)’s start time").sectionTitle()
            Text("Tasks without a set time follow in order from here.").caption()
            DatePicker("Start learning", selection: $time, displayedComponents: .hourAndMinute)
            Button("Set times") { onSave(time); dismiss() }.buttonStyle(.primaryHomeschool)
            Button("Keep it flexible") { onSave(nil); dismiss() }.frame(maxWidth: .infinity)
        }
        .padding(24)
        .background(Theme.background)
    }
}

/// Only unused weekdays are offered, so a seven-day routine never shows an extra add tile.
struct AddLearningDayButton: View {
    let days: [String]
    let onSelect: (String) -> Void
    private var available: [String] { WeeklyPlan.dayNames.filter { !days.contains($0) } }

    var body: some View {
        if !available.isEmpty {
            Menu {
                ForEach(available, id: \.self) { day in
                    Button(WeeklyPlan.fullDayNames[WeeklyPlan.dayNames.firstIndex(of: day)!]) { onSelect(day) }
                }
            } label: {
                VStack(spacing: 7) {
                    Image(systemName: "plus").font(.system(size: 22, weight: .medium))
                    Text("Add day").scaledFont(11, weight: .semibold, maxScale: 1.25)
                }
                .foregroundStyle(WeekStyle.purple)
                .frame(width: 74, height: 76)
                .background(Theme.surface.opacity(0.6), in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(WeekStyle.purple.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add a learning day")
            .accessibilityIdentifier("week.addDay")
        }
    }
}

struct ActivityRemovalNotice: View {
    let activity: WeekActivity
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.uturn.backward.circle").font(.system(size: 21))
                .foregroundStyle(WeekStyle.purple)
            VStack(alignment: .leading, spacing: 2) {
                Text("Removed from \(activity.date.formatted(.dateTime.weekday(.wide)))")
                    .scaledFont(12, weight: .semibold, maxScale: 1.25)
                Text(activity.title).scaledFont(11, maxScale: 1.25)
                    .foregroundStyle(Theme.secondary).lineLimit(1)
            }
            Spacer(minLength: 4)
            Button("Undo", action: onUndo)
                .scaledFont(14, weight: .semibold, maxScale: 1.25)
                .foregroundStyle(WeekStyle.purple).frame(minWidth: 44, minHeight: 44)
                .accessibilityIdentifier("home.undoRemoval")
        }
        .padding(.horizontal, 14).padding(.vertical, 5)
        .gatherGlass(in: RoundedRectangle(cornerRadius: 20), tint: Theme.lilac.opacity(0.6))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
