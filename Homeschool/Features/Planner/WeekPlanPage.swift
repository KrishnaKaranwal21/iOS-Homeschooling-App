import SwiftUI

struct WeekPlanPage: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let child: Child
    let backTitle: String
    let onAddChild: () -> Void
    let isSheet: Bool
    let onSelectDate: (Date) -> Void
    @State var plan: WeeklyPlan
    @State var selectedDay: String
    struct TaskEditorRequest: Identifiable {
        let id = UUID()
        let activity: WeekActivity
        let isEditing: Bool
    }
    @State var taskEditor: TaskEditorRequest?
    @State var saved = false
    @State var showCompleted = false
    @State var removedActivity: WeekActivity?
    @State var removedIndex = 0
    @State var completionFeedback = 0
    @State var wrapUpRequest: DayLearningSummary?

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

    var dayIndex: Int { WeeklyPlan.dayNames.firstIndex(of: selectedDay) ?? 0 }
    var dailyMinutes: Int { plan.minutes(on: selectedDay) }
    var remaining: [WeekActivity] { plan.remainingActivities(on: selectedDay) }
    var completed: [WeekActivity] { plan.completedActivities(on: selectedDay) }
    var rowAnimation: Animation { reduceMotion ? .easeOut(duration: 0.18) : .spring(response: 0.38, dampingFraction: 0.88) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if isSheet {
                    plannerHeader
                    plannerIntro
                    plannerRhythm
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(Theme.pink, in: .rect(cornerRadius: 28))
                } else {
                header
                Text("Your week")
                    .textCase(.uppercase)
                    .scaledFont(11, weight: .semibold, maxScale: 1.2)
                    .foregroundStyle(Color(hex: 0x8D4540))
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
                        .caption().foregroundStyle(Color(hex: 0x9C4A4B))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .scrollTitleBar(isSheet ? "Your plan" : "Your week")
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

    var plannerHeader: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").accessibilityHidden(true).scaledFont(16, weight: .semibold)
                    .frame(width: 44, height: 44)
                    .gatherGlass(in: Circle(), tint: Theme.lilac.opacity(0.4))
            }
            .buttonStyle(.plain).accessibilityLabel("Back")
            Spacer(minLength: 0)
        }
    }

    var plannerIntro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your plan")
                .pageTitle()
                .foregroundStyle(Theme.ink)
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

    var header: some View {
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
                    Image(systemName: "chevron.down").accessibilityHidden(true).scaledFont(11, weight: .semibold)
                }
                .padding(.leading, 6).padding(.trailing, 12).padding(.vertical, 6)
                .background(WeekStyle.field, in: Capsule())
            }
        }
        .buttonStyle(.plain)
    }

    func complete(_ activity: WeekActivity) {
        withAnimation(rowAnimation) {
            guard plan.complete(activity.id) else { return }
            completionFeedback += 1
            requestWrapUpIfFinished()
        }
    }

    func remove(_ activity: WeekActivity) {
        guard let index = plan.activities.firstIndex(where: { $0.id == activity.id }) else { return }
        withAnimation(rowAnimation) {
            removedIndex = index
            removedActivity = plan.removeForDay(activity.id)
            if isSheet { wrapUpRequest = nil } else { requestWrapUpIfFinished() }
        }
    }

    func undoRemoval() {
        guard let activity = removedActivity else { return }
        withAnimation(rowAnimation) {
            plan.activities.insert(activity, at: min(removedIndex, plan.activities.count))
            removedActivity = nil
            wrapUpRequest = nil
            selectedDay = plan.day(for: activity.date)
        }
    }

    func requestWrapUpIfFinished() {
        // An empty or entirely removed day is not a completed learning day.
        guard remaining.isEmpty, !completed.isEmpty else { return }
        wrapUpRequest = plan.learningSummary(on: selectedDay, childName: child.displayName)
    }

    func scheduledTime(for activity: WeekActivity) -> Date? {
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
