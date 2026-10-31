import SwiftUI

struct ProgressDashboardView: View {
    @Environment(AppState.self) private var state
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedDay = WeeklyPlan.dayNames[(Calendar.current.component(.weekday, from: .now) + 5) % 7]
    @State private var metric: ProgressMetric = .time
    @State private var showAddChild = false
    @Namespace private var selectionAnimation

    private var plan: WeeklyPlan { state.weeklyPlans[state.child.id.uuidString] ?? .firstWeek(for: state.child) }
    private var progress: LearningProgress { LearningProgress(plan: plan, selectedSubjects: state.child.subjectNames) }
    private var day: DayLearningProgress { progress.day(selectedDay) }
    private var selectionMotion: Animation { reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.38, dampingFraction: 0.86) }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        controls
                        weeklyChart(height: min(218, max(170, geometry.size.height * 0.30)))
                        Text("Tap a day. Watch its story unfold.")
                            .scaledFont(12, maxScale: 1.25)
                            .foregroundStyle(ProgressPalette.purple)
                            .frame(maxWidth: .infinity)
                            .padding(.top, -4)
                        weeklyTotals
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .padding(.bottom, 24)

                    VStack(alignment: .leading, spacing: 28) {
                        dayDetail
                        subjectSection
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 24)
                    .padding(.bottom, 28)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white, in: UnevenRoundedRectangle(topLeadingRadius: 38, topTrailingRadius: 38))
                    .padding(.horizontal, 10)
                }
                .frame(maxWidth: 650)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            .background(ProgressPalette.background.ignoresSafeArea())
        }
        .foregroundStyle(Theme.ink)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showAddChild) { AddChildFlow() }
        .onChange(of: state.child.id) { _, _ in
            selectedDay = plan.day(for: .now)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Progress").pageTitle()
            Spacer(minLength: 0)
            ChildSwitcherMenu(onAddChild: { showAddChild = true }) {
                HStack(spacing: 8) {
                    AvatarView(initials: String(state.child.displayName.prefix(1)).uppercased(), color: Theme.lavender, size: 27)
                    Text(state.child.displayName).scaledFont(15, weight: .medium, maxScale: 1.2).lineLimit(1)
                    Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold))
                }
                .padding(.leading, 6).padding(.trailing, 12).padding(.vertical, 7)
                .background(.white.opacity(0.38), in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.8), lineWidth: 1))
                .shadow(color: ProgressPalette.purple.opacity(0.04), radius: 4, y: 2)
            }
        }
    }

    private var controls: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 0) {
                ForEach(ProgressMetric.allCases) { option in
                    Button {
                        withAnimation(selectionMotion) { metric = option }
                    } label: {
                        Text(option.rawValue)
                            .scaledFont(13, weight: metric == option ? .semibold : .medium, maxScale: 1.2)
                            .frame(maxWidth: .infinity).frame(height: 30)
                            .background {
                                if metric == option {
                                    Capsule().fill(.white).matchedGeometryEffect(id: "metric", in: selectionAnimation)
                                        .shadow(color: ProgressPalette.purple.opacity(0.06), radius: 3, y: 1)
                                }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(metric == option ? .isSelected : [])
                }
            }
            .padding(3)
            .frame(width: 180)
            .background(ProgressPalette.purple.opacity(0.06), in: Capsule())
            .accessibilityLabel("Progress measurement")
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 4) {
                Text("YOUR WEEK")
                    .scaledFont(9, weight: .semibold, maxScale: 1.2).tracking(1.7)
                Text(weekRange)
                    .scaledFont(12, weight: .medium, maxScale: 1.2)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(ProgressPalette.purple)
        }
    }

    private var weekRange: String {
        let start = plan.weekStart.formatted(.dateTime.day())
        let end = plan.weekEnd.formatted(.dateTime.day().month(.abbreviated))
        if Calendar.current.component(.month, from: plan.weekStart) == Calendar.current.component(.month, from: plan.weekEnd) {
            return "\(start)–\(end)"
        }
        return "\(plan.weekStart.formatted(.dateTime.day().month(.abbreviated))) – \(end)"
    }

    private func weeklyChart(height: CGFloat) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("A LITTLE LEARNING, EVERY DAY")
                    .scaledFont(9, weight: .semibold, maxScale: 1.15).tracking(1.2)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                legend("Logged", color: ProgressPalette.inactive)
                legend("Planned", color: .white.opacity(0.65))
            }
            .foregroundStyle(ProgressPalette.purple)
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach((0...4).reversed(), id: \.self) { tick in
                        Text(axisLabel(tick: tick))
                            .scaledFont(9, maxScale: 1.2)
                            .foregroundStyle(ProgressPalette.purple.opacity(0.8))
                            .frame(height: tick == 0 ? 12 : height / 4, alignment: .topLeading)
                    }
                }
                .frame(width: 25)
                HStack(alignment: .top, spacing: 3) {
                    ForEach(WeeklyPlan.dayNames, id: \.self) { name in
                        chartColumn(name, height: height)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Weekly \(metric.rawValue.lowercased()) chart")
    }

    private var chartMaximum: Int {
        let values = WeeklyPlan.dayNames.map { name in
            let value = progress.day(name)
            return metric == .time ? value.plannedMinutes : value.activities.count
        }
        let largest = values.max() ?? 0
        if metric == .time { return max(60, Int(ceil(Double(largest) / 60)) * 60) }
        return max(4, Int(ceil(Double(largest) / 4)) * 4)
    }

    private func axisLabel(tick: Int) -> String {
        let value = Double(chartMaximum) * Double(tick) / 4
        guard tick > 0 else { return "0" }
        if metric == .activities { return "\(Int(value))" }
        let hours = value / 60
        return hours.formatted(.number.precision(.fractionLength(0...1))) + "h"
    }

    private func chartColumn(_ name: String, height: CGFloat) -> some View {
        let value = progress.day(name)
        let planned = metric == .time ? value.plannedMinutes : value.activities.count
        let logged = metric == .time ? value.loggedMinutes : value.completed.count
        let isSelected = selectedDay == name
        let plannedHeight = height * CGFloat(planned) / CGFloat(chartMaximum)
        let loggedHeight = height * CGFloat(logged) / CGFloat(chartMaximum)
        return Button {
            withAnimation(selectionMotion) { selectedDay = name }
        } label: {
            VStack(spacing: 10) {
                ZStack(alignment: .bottom) {
                    if planned > 0 {
                        Capsule().fill(.white.opacity(0.48))
                            .frame(height: max(4, plannedHeight))
                    } else {
                        Capsule().fill(ProgressPalette.inactive.opacity(0.65)).frame(height: 3)
                    }
                    if logged > 0 {
                        Capsule().fill(isSelected ? ProgressPalette.purple : ProgressPalette.inactive)
                            .frame(height: max(5, loggedHeight))
                            .overlay(alignment: .top) {
                                if value.isComplete && loggedHeight >= 24 {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                                        .padding(.top, 10)
                                }
                            }
                    }
                }
                .frame(maxWidth: 31)
                .frame(maxWidth: .infinity)
                .frame(height: height, alignment: .bottom)
                Text(name)
                    .scaledFont(11, weight: isSelected ? .semibold : .regular, maxScale: 1.2)
                    .frame(maxWidth: .infinity).frame(height: 29)
                    .background {
                        if isSelected {
                            Capsule().fill(ProgressPalette.coral)
                                .matchedGeometryEffect(id: "selectedDay", in: selectionAnimation)
                        }
                    }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(WeeklyPlan.fullDayNames[WeeklyPlan.dayNames.firstIndex(of: name)!]), \(LearningProgress.duration(value.loggedMinutes)) logged, \(value.completed.count) of \(value.activities.count) activities completed")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func legend(_ title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(title).scaledFont(9, maxScale: 1.2)
        }
    }

    private var weeklyTotals: some View {
        HStack(alignment: .top, spacing: 0) {
            statistic(metric == .time ? LearningProgress.duration(progress.loggedMinutes) : "\(progress.completedCount)",
                      caption: metric == .time ? "Logged this week" : "Completed this week")
            Rectangle().fill(ProgressPalette.purple.opacity(0.12)).frame(width: 1, height: 39)
            statistic(metric == .time ? LearningProgress.duration(progress.plannedMinutes) : "\(progress.activityCount)",
                      caption: "Planned this week")
                .padding(.leading, 13)
            Rectangle().fill(ProgressPalette.purple.opacity(0.12)).frame(width: 1, height: 39)
            statistic("\(Int(((metric == .time ? progress.timeFraction : progress.activityFraction) * 100).rounded()))%", caption: "Completed")
                .padding(.leading, 13)
        }
    }

    private func statistic(_ value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value).scaledFont(22, weight: .heavy, maxScale: 1.15)
                .tracking(-0.7).lineLimit(1).minimumScaleFactor(0.65)
                .contentTransition(.numericText())
            Text(caption).scaledFont(9, maxScale: 1.2)
                .foregroundStyle(ProgressPalette.purple).lineLimit(1).minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var dayDetail: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(metric == .time ? LearningProgress.duration(day.loggedMinutes) : "\(day.completed.count) \(day.completed.count == 1 ? "activity" : "activities")")
                        .scaledFont(metric == .time ? 46 : 36, weight: .heavy, maxScale: 1.15)
                        .tracking(-2).lineLimit(1).minimumScaleFactor(0.6)
                        .contentTransition(.numericText())
                    Text("Learning · \(WeeklyPlan.fullDayNames[WeeklyPlan.dayNames.firstIndex(of: selectedDay)!])")
                        .scaledFont(15, weight: .medium, maxScale: 1.25)
                    Text(day.date.formatted(.dateTime.day().month(.wide)))
                        .scaledFont(13, maxScale: 1.25).foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 0)
                NavigationLink {
                    FirstWeekView(initialDay: selectedDay, backTitle: "Progress")
                } label: {
                    Label("Plan", systemImage: "plus")
                        .scaledFont(14, weight: .medium, maxScale: 1.2)
                        .padding(.horizontal, 16).frame(height: 44)
                        .background(.white, in: Capsule())
                        .overlay(Capsule().strokeBorder(Color(hex: 0xE5E5E5), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Plan \(WeeklyPlan.fullDayNames[WeeklyPlan.dayNames.firstIndex(of: selectedDay)!])")
            }
            HStack(alignment: .top, spacing: 10) {
                dayStatistic(LearningProgress.duration(day.plannedMinutes), caption: "Planned")
                dayStatistic("\(day.completed.count) / \(day.activities.count)", caption: "Activities")
                dayStatistic(LearningProgress.duration(day.remainingMinutes), caption: "Left to explore")
            }
            Divider().overlay(Color(hex: 0xEEEEEE))
            activityList
        }
    }

    private func dayStatistic(_ value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value).scaledFont(19, weight: .bold, maxScale: 1.2)
                .tracking(-0.6).lineLimit(1).minimumScaleFactor(0.65)
                .contentTransition(.numericText())
            Text(caption).scaledFont(10, maxScale: 1.2).foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var activityList: some View {
        if day.activities.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("A little breathing room.").scaledFont(17, weight: .semibold, maxScale: 1.2)
                Text("No activities planned for this day. Add something with + Plan whenever you’re ready.").caption()
            }
            .padding(.vertical, 8)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                Text("THE DAY’S LEARNING")
                    .scaledFont(10, weight: .semibold, maxScale: 1.2)
                    .tracking(1.3).foregroundStyle(Theme.muted)
                ForEach(day.activities) { activity in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: activity.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(activity.isDone ? ProgressPalette.purple : Color(hex: 0xD4D0E3))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.subject.uppercased()).scaledFont(9, weight: .medium, maxScale: 1.2)
                                .tracking(0.4).foregroundStyle(Theme.muted)
                            Text(activity.title).scaledFont(14, weight: .medium, maxScale: 1.25)
                        }
                        Spacer(minLength: 0)
                        Text("\(activity.minutes)m").scaledFont(11, weight: .medium, maxScale: 1.2)
                            .foregroundStyle(Theme.muted)
                            .padding(.horizontal, 9).padding(.vertical, 5)
                            .background(Theme.field, in: Capsule())
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(activity.isDone ? "Completed" : "Planned")
                    if activity.id != day.activities.last?.id { Divider().opacity(0.5) }
                }
            }
        }
    }

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider().padding(.bottom, 6)
            VStack(alignment: .leading, spacing: 5) {
                Text("Subject progress").sectionTitle()
                Text("Your chosen subjects · this weekly plan")
                    .scaledFont(12, maxScale: 1.25).foregroundStyle(Theme.muted)
            }
            ForEach(progress.subjects) { subject in
                SubjectProgressRow(subject: subject)
            }
            if progress.subjects.isEmpty {
                Text("Your selected subjects will appear here when you build your weekly plan.").caption()
            }
        }
    }
}

private enum ProgressMetric: String, Identifiable, CaseIterable {
    case time = "Time", activities = "Activities"
    var id: String { rawValue }
}

enum ProgressPalette {
    static let background = Color(hex: 0xE6DEFF)
    static let purple = Color(hex: 0x4430A5)
    static let inactive = Color(hex: 0x9B90B9)
    static let coral = Color(hex: 0xFFC9C5)
}

private struct SubjectProgressRow: View {
    let subject: SubjectLearningProgress
    private var percent: Int { Int((subject.fraction * 100).rounded()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(ProgressPalette.purple)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.85), in: .rect(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.name).scaledFont(15, weight: .semibold, maxScale: 1.25)
                    Text("\(subject.completedCount) of \(subject.activities.count) activities completed")
                        .scaledFont(11, maxScale: 1.25).foregroundStyle(Theme.secondary)
                }
                Spacer(minLength: 0)
                Text("\(percent)%").scaledFont(20, weight: .bold, maxScale: 1.2)
                    .foregroundStyle(ProgressPalette.purple)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(ProgressPalette.purple.opacity(0.08))
                    Capsule().fill(ProgressPalette.purple)
                        .frame(width: geometry.size.width * subject.fraction)
                }
            }
            .frame(height: 6)
            HStack {
                Text("\(LearningProgress.duration(subject.loggedMinutes)) logged")
                Spacer()
                Text(subject.plannedMinutes == 0 ? "Not planned yet" : "\(LearningProgress.duration(subject.plannedMinutes)) planned")
            }
            .scaledFont(10, maxScale: 1.25).foregroundStyle(Theme.secondary)
        }
        .padding(15)
        .background(ProgressPalette.background.opacity(0.38), in: .rect(cornerRadius: 19))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(subject.name), \(percent) percent of planned learning completed, \(subject.completedCount) of \(subject.activities.count) activities, \(LearningProgress.duration(subject.loggedMinutes)) logged")
    }

    private var symbol: String {
        switch subject.id {
        case "mathematics": return "function"
        case "science": return "flask"
        case "computer skills": return "chevron.left.forwardslash.chevron.right"
        case "art & craft": return "paintpalette"
        case "english", "hindi": return "text.book.closed"
        default: return "book.closed"
        }
    }
}
