import SwiftUI

/// Keeps the Home tab bar visible while the family reviews their first week.
struct FirstWeekView: View {
    @Environment(AppState.self) private var state
    @State private var showAddChild = false

    var body: some View {
        WeekPlanPage(child: state.child, savedPlan: state.weeklyPlans[state.child.id.uuidString],
                     onAddChild: { showAddChild = true })
            .id(state.child.id)
            .fullScreenCover(isPresented: $showAddChild) { AddChildFlow() }
    }
}

private struct WeekPlanPage: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let child: Child
    let onAddChild: () -> Void
    @State private var plan: WeeklyPlan
    @State private var selectedDay: String
    @State private var showTask = false
    @State private var editingActivity: WeekActivity?
    @State private var showTimes = false
    @State private var saved = false
    @State private var showCompleted = false
    @State private var removedActivity: WeekActivity?
    @State private var removedIndex = 0
    @State private var completionFeedback = 0
    @State private var wrapUpRequest: DayLearningSummary?

    init(child: Child, savedPlan: WeeklyPlan?, onAddChild: @escaping () -> Void) {
        self.child = child
        self.onAddChild = onAddChild
        let plan = savedPlan ?? .firstWeek(for: child)
        _plan = State(initialValue: plan)
        _selectedDay = State(initialValue: plan.days.first ?? "Mon")
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
                header
                Text(saved ? "WEEK 1" : "WEEK 1 · DRAFT")
                    .scaledFont(11, weight: .semibold, maxScale: 1.2)
                    .foregroundStyle(Color(hex: 0x8D4540))
                    .padding(.horizontal, 15).padding(.vertical, 6)
                    .background(WeekStyle.pink, in: Capsule())

                Text("A week, shaped\naround \(child.displayName).")
                    .pageTitle()
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(child.programmeText).scaledFont(16, weight: .semibold, maxScale: 1.2)
                    Text("\(plan.days.count) days · \(plan.days.count * plan.hoursPerDay) learning hours")
                        .scaledFont(14, maxScale: 1.3)
                        .foregroundStyle(WeekStyle.secondary)
                }
                .padding(.horizontal, 18).padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(WeekStyle.lavender, in: .rect(cornerRadius: 16))

                Text("Your chosen rhythm").sectionTitle()
                rhythm
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
                    Text("This day is \(dailyMinutes - plan.hoursPerDay * 60) min over your chosen rhythm. You can adjust any task before saving.")
                        .caption().foregroundStyle(Color(hex: 0x9C4A4B))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background)
        .foregroundStyle(Theme.ink)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .sheet(isPresented: $showTask) {
            WeekTaskSheet(activity: editingActivity ?? WeekActivity(date: plan.date(for: selectedDay)),
                          week: plan, isEditing: editingActivity != nil) { activity in
                if let index = plan.activities.firstIndex(where: { $0.id == activity.id }), editingActivity != nil {
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
            .presentationDetents([.fraction(0.82), .large])
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
        .onChange(of: plan) { _, _ in
            saved = state.weeklyPlans[child.id.uuidString] == plan
            if !remaining.isEmpty { wrapUpRequest = nil }
        }
        .onChange(of: selectedDay) { _, _ in
            wrapUpRequest = nil
            showCompleted = false
        }
        .task(id: wrapUpRequest?.id) {
            guard let summary = wrapUpRequest else { return }
            do { try await Task.sleep(for: .milliseconds(reduceMotion ? 180 : 450)) }
            catch { return }
            guard !Task.isCancelled, selectedDay == summary.day, remaining.isEmpty else { return }
            withAnimation(.easeOut(duration: 0.22)) { state.dailyWrapUp = summary }
        }
        .sensoryFeedback(.success, trigger: completionFeedback)
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Label("Home", systemImage: "chevron.left")
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
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(Array(plan.days.enumerated()), id: \.element) { index, day in
                    Button { selectedDay = day } label: {
                        VStack(spacing: 5) {
                            Text(day.uppercased()).scaledFont(18, weight: .heavy, maxScale: 1.2)
                            Capsule().fill(Color(hex: 0xFF8D9A)).frame(width: 25, height: 6)
                            Text("\(plan.hoursPerDay)h")
                                .scaledFont(16, weight: .medium, maxScale: 1.2)
                                .foregroundStyle(WeekStyle.secondary)
                        }
                        .frame(width: 79, height: 76)
                        .background(selectedDay == day ? Color.white : WeekStyle.pink, in: .rect(cornerRadius: 9))
                        .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(selectedDay == day ? WeekStyle.purple : .clear, lineWidth: 1))
                        .rotationEffect(.degrees([-5, 5, -5, 5][index % 4]))
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(WeeklyPlan.fullDayNames[WeeklyPlan.dayNames.firstIndex(of: day)!]), \(plan.hoursPerDay) hours")
                    .accessibilityAddTraits(day == selectedDay ? .isSelected : [])
                }
            }
            .padding(.horizontal, 5)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.trailing, 5)
        .padding(.horizontal, -5)
    }

    private var dayHeading: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(WeeklyPlan.fullDayNames[dayIndex]).sectionTitle()
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
        HStack(spacing: 0) {
            Button {
                editingActivity = activity
                showTask = true
            } label: {
                HStack(spacing: 10) {
                    Text("\(activity.minutes) min")
                        .scaledFont(14, weight: .medium, maxScale: 1.2)
                        .foregroundStyle(activity.subject.lowercased().contains("math") ? Color(hex: 0x8D4540) : WeekStyle.purple)
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

            Button { complete(activity) } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(WeekStyle.purple)
                    .frame(width: 30, height: 30)
                    .background(WeekStyle.field, in: Circle())
                    .overlay(Circle().strokeBorder(Color(hex: 0xB5A9DA), lineWidth: 1))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Complete \(activity.title)")
            .accessibilityIdentifier("week.complete.\(activity.id)")

            Button { remove(activity) } label: {
                Image(systemName: "minus.circle")
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(Color(hex: 0x9C6C73))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(activity.title) for this day")
            .accessibilityHint("Other days stay the same. You can undo this removal.")
        }
        .padding(.leading, 11).padding(.trailing, 5).padding(.vertical, 3)
        .frame(minHeight: 52)
        .background(.white, in: .rect(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(WeekStyle.border, lineWidth: 0.8))
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
            HStack {
                Spacer()
                Button {
                    editingActivity = nil
                    showTask = true
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
            } label: {
                HStack(spacing: 6) {
                    if saved { Image(systemName: "checkmark") }
                    Text(saved ? "Week saved" : "Save this week")
                }
                    .scaledFont(16, weight: .semibold, maxScale: 1.2)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .background(Color(hex: 0x2D3531), in: Capsule())
            }
            .buttonStyle(.plain)
            Text("Review now. Adjust anytime.")
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
        .background(.white, in: .rect(cornerRadius: 20))
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
                                    plan.activities[index].isDone = false
                                    wrapUpRequest = nil
                                    state.saveWeek(plan, for: child.id)
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
            state.saveWeek(plan, for: child.id)
            requestWrapUpIfFinished()
        }
    }

    private func remove(_ activity: WeekActivity) {
        guard let index = plan.activities.firstIndex(where: { $0.id == activity.id }) else { return }
        withAnimation(rowAnimation) {
            removedIndex = index
            removedActivity = plan.removeForDay(activity.id)
            state.saveWeek(plan, for: child.id)
            requestWrapUpIfFinished()
        }
    }

    private func undoRemoval() {
        guard let activity = removedActivity else { return }
        withAnimation(rowAnimation) {
            plan.activities.insert(activity, at: min(removedIndex, plan.activities.count))
            removedActivity = nil
            wrapUpRequest = nil
            selectedDay = plan.day(for: activity.date)
            state.saveWeek(plan, for: child.id)
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
    static let pink = Color(hex: 0xFFC4C8)
    static let lavender = Color(hex: 0xE9E5FF)
    static let field = Color(hex: 0xF4F2FF)
    static let secondary = Color(hex: 0x817D9F)
    static let purple = Color(hex: 0x2B2859)
    static let border = Color(hex: 0xDFDDED)
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
