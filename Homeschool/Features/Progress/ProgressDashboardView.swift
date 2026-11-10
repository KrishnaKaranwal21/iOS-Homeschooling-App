import SwiftUI

struct ProgressDashboardView: View {
    @Environment(AppState.self) private var state
    @State private var showAddChild = false

    var body: some View {
        ProgressLearningPage(child: state.child, onAddChild: { showAddChild = true })
            .id(state.child.id)
            .fullScreenCover(isPresented: $showAddChild) { AddChildFlow() }
    }
}

private struct ProgressLearningPage: View {
    @Environment(AppState.self) private var state
    let child: Child
    let onAddChild: () -> Void
    @State private var generatedPlan: WeeklyPlan
    @State private var expandedSubjectID: String?
    @State private var completionFeedback = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedDate: Date
    @State private var range: ProgressRange = .week
    @State private var selectedBucketID: String?

    init(child: Child, onAddChild: @escaping () -> Void) {
        self.child = child
        self.onAddChild = onAddChild
        _generatedPlan = State(initialValue: .firstWeek(for: child))
        _selectedDate = State(initialValue: Calendar.current.startOfDay(for: .now))
    }

    private var plan: WeeklyPlan { state.weeklyPlans[child.id.uuidString] ?? generatedPlan }
    private var progress: LearningProgress { LearningProgress(plan: plan, selectedSubjects: state.child.subjectNames) }
    private var selectedDay: String { plan.day(for: selectedDate) }
    private var day: DayLearningProgress {
        DayLearningProgress(name: selectedDay, date: selectedDate,
                            activities: plan.activities.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) })
    }
    private var timeline: ProgressTimeline { ProgressTimeline(plan: plan, range: range, selectedDate: selectedDate) }
    private var selectedBucket: ProgressChartBucket? { timeline.buckets.first { $0.id == selectedBucketID } }
    private var isRangeOverview: Bool { range != .day && selectedBucketID == nil }
    private var detail: DayLearningProgress {
        DayLearningProgress(name: selectedDay, date: selectedDate,
                            activities: isRangeOverview ? timeline.activities : day.activities)
    }
    private var selectedDateIsInPlan: Bool {
        selectedDate >= Calendar.current.startOfDay(for: plan.weekStart)
            && selectedDate < Calendar.current.date(byAdding: .day, value: 7, to: Calendar.current.startOfDay(for: plan.weekStart))!
    }
    private var selectionMotion: Animation { reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.38, dampingFraction: 0.86) }

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 18) {
                            header
                            controls
                            learningChart(height: min(218, max(170, geometry.size.height * 0.30)))
                            Text(chartHint)
                                .scaledFont(12, maxScale: 1.25)
                                .foregroundStyle(ProgressPalette.purple)
                                .frame(maxWidth: .infinity)
                                .padding(.top, -4)
                            rangeTotals
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
                        .background {
                            UnevenRoundedRectangle(topLeadingRadius: 38, topTrailingRadius: 38)
                                .fill(Theme.surface)
                                .mask {
                                    VStack(spacing: 0) {
                                        Color.black
                                        LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                                            .frame(height: 72)
                                    }
                                }
                        }
                        .padding(.horizontal, 10)
                    }
                    .frame(maxWidth: 650)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
                .background(ProgressPalette.background.ignoresSafeArea())
                .onChange(of: expandedSubjectID) { _, subjectID in
                    guard let subjectID else { return }
                    withAnimation(reduceMotion ? nil : selectionMotion) {
                        scrollProxy.scrollTo(subjectID, anchor: .top)
                    }
                }
            }
        }
        .foregroundStyle(Theme.ink)
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.success, trigger: completionFeedback)
        .sensoryFeedback(.selection, trigger: selectedBucketID)
        .onAppear {
            if !selectedDateIsInPlan { selectedDate = plan.date(for: selectedDay) }
            selectedBucketID = nil
        }
        .onChange(of: range) { _, _ in
            expandedSubjectID = nil
            if range == .week && !selectedDateIsInPlan { selectedDate = plan.date(for: selectedDay) }
            selectedBucketID = nil
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Progress").pageTitle()
            Spacer(minLength: 0)
            ChildSwitcherMenu(onAddChild: onAddChild) {
                HStack(spacing: 8) {
                    AvatarView(initials: String(state.child.displayName.prefix(1)).uppercased(), color: Theme.lavender, size: 27)
                    Text(state.child.displayName).scaledFont(15, weight: .medium, maxScale: 1.2).lineLimit(1)
                    Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold))
                }
                .padding(.leading, 6).padding(.trailing, 12).padding(.vertical, 7)
                .gatherGlass(in: Capsule())
            }
        }
    }

    private var controls: some View {
        HStack(alignment: .center, spacing: 12) {
            Picker("Progress range", selection: $range.animation(selectionMotion)) {
                ForEach(ProgressRange.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 196)
            .frame(minHeight: 44)
            .accessibilityIdentifier("progress.range")
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 4) {
                Text("YOUR \(range.rawValue.uppercased())")
                    .scaledFont(9, weight: .semibold, maxScale: 1.2).tracking(1.7)
                Text(rangeLabel)
                    .scaledFont(12, weight: .medium, maxScale: 1.2)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(ProgressPalette.purple)
        }
    }

    private var rangeLabel: String {
        switch range {
        case .day: selectedDate.formatted(.dateTime.day().month(.abbreviated))
        case .week: weekRange
        case .month: selectedDate.formatted(.dateTime.month(.wide).year())
        }
    }

    private var chartHint: String {
        if range == .day {
            return selectedBucket?.title ?? (day.activities.isEmpty ? "A little room to rest or explore." : "Tap an activity. See your little wins.")
        }
        return "Tap a day. Watch its story unfold."
    }

    private var weekRange: String {
        let start = plan.weekStart.formatted(.dateTime.day())
        let end = plan.weekEnd.formatted(.dateTime.day().month(.abbreviated))
        if Calendar.current.component(.month, from: plan.weekStart) == Calendar.current.component(.month, from: plan.weekEnd) {
            return "\(start)–\(end)"
        }
        return "\(plan.weekStart.formatted(.dateTime.day().month(.abbreviated))) – \(end)"
    }

    private func learningChart(height: CGFloat) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text(range == .day ? "LITTLE WINS, ONE AT A TIME" : "A LITTLE LEARNING, EVERY DAY")
                    .scaledFont(9, weight: .semibold, maxScale: 1.15).tracking(1.2)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                legend("Logged", color: ProgressPalette.logged)
                legend("Planned", color: Theme.surface.opacity(0.65))
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
                if timeline.buckets.isEmpty {
                    Text("Your planned activities will appear here.")
                        .scaledFont(13, maxScale: 1.25)
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, minHeight: height)
                } else {
                    HStack(alignment: .top, spacing: range == .month ? 2 : 3) {
                        ForEach(Array(timeline.buckets.enumerated()), id: \.element.id) { index, bucket in
                            chartColumn(bucket, index: index, height: height)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(range.rawValue) learning time chart")
    }

    private var chartMaximum: Int {
        let largest = timeline.buckets.map(\.plannedMinutes).max() ?? 0
        return max(60, Int(ceil(Double(largest) / 60)) * 60)
    }

    private func axisLabel(tick: Int) -> String {
        let value = Double(chartMaximum) * Double(tick) / 4
        guard tick > 0 else { return "0" }
        if range == .day && value < 60 { return value.formatted(.number.precision(.fractionLength(0...1))) + "m" }
        return (value / 60).formatted(.number.precision(.fractionLength(0...1))) + "h"
    }

    private func chartColumn(_ bucket: ProgressChartBucket, index: Int, height: CGFloat) -> some View {
        let isSelected = selectedBucketID == bucket.id
        let plannedHeight = height * CGFloat(bucket.plannedMinutes) / CGFloat(chartMaximum)
        let loggedHeight = height * CGFloat(bucket.loggedMinutes) / CGFloat(chartMaximum)
        let showLabel = range != .month || index.isMultiple(of: 5) || index == timeline.buckets.count - 1
        return Button {
            withAnimation(selectionMotion) {
                selectedBucketID = bucket.id
                selectedDate = bucket.date
            }
        } label: {
            VStack(spacing: 10) {
                Group {
                    if bucket.plannedMinutes > 0 {
                        Capsule().fill(Theme.surface.opacity(isSelected ? 0.72 : 0.42))
                            .frame(height: max(4, plannedHeight))
                            .overlay(alignment: .bottom) {
                                if bucket.loggedMinutes > 0 {
                                    Rectangle()
                                        .fill(isSelected ? ProgressPalette.purple : ProgressPalette.logged)
                                        .frame(height: min(max(4, plannedHeight), max(1, loggedHeight)))
                                        .overlay(alignment: .top) {
                                            if bucket.isComplete && loggedHeight >= 24 && range != .month {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.background)
                                                    .padding(.top, 10)
                                            }
                                        }
                                }
                            }
                            .clipShape(Capsule())
                    } else {
                        Capsule().fill(ProgressPalette.purple.opacity(isSelected ? 0.7 : 0.2)).frame(height: 3)
                    }
                }
                .frame(maxWidth: range == .month ? 8 : 31)
                .frame(maxWidth: .infinity)
                .frame(height: height, alignment: .bottom)
                Text(showLabel ? bucket.label : "")
                    .scaledFont(range == .month ? 8 : 11, weight: isSelected ? .bold : .regular, maxScale: 1.2)
                    .foregroundStyle(isSelected ? Theme.ink : ProgressPalette.purple.opacity(0.7))
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(maxWidth: .infinity).frame(height: 29)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(bucket.title), \(LearningProgress.duration(bucket.loggedMinutes)) logged, \(LearningProgress.duration(bucket.plannedMinutes)) planned")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("progress.bar.\(index)")
    }

    private func legend(_ title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(title).scaledFont(9, maxScale: 1.2)
        }
    }

    private var rangeTotals: some View {
        let percentage = Int((timeline.fraction * 100).rounded())
        return HStack(alignment: .top, spacing: 0) {
            statistic(LearningProgress.duration(timeline.loggedMinutes), caption: "Logged this \(range.rawValue.lowercased())")
            Rectangle().fill(ProgressPalette.purple.opacity(0.12)).frame(width: 1, height: 39)
            statistic(LearningProgress.duration(timeline.plannedMinutes),
                      caption: range == .day ? "Daily goal" : "Planned this \(range.rawValue.lowercased())")
                .padding(.leading, 13)
            Rectangle().fill(ProgressPalette.purple.opacity(0.12)).frame(width: 1, height: 39)
            statistic("\(percentage)%", caption: "Completed")
                .padding(.leading, 13)
        }
        .accessibilityIdentifier("progress.rangeTotals")
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
                    Text(LearningProgress.duration(detail.loggedMinutes))
                        .scaledFont(46, weight: .heavy, maxScale: 1.15)
                        .tracking(-2).lineLimit(1).minimumScaleFactor(0.6)
                        .contentTransition(.numericText())
                    Text(isRangeOverview ? "Learning · This \(range.rawValue.lowercased())" : "Learning · \(WeeklyPlan.fullDayNames[WeeklyPlan.dayNames.firstIndex(of: selectedDay)!])")
                        .scaledFont(15, weight: .medium, maxScale: 1.25)
                    Text(isRangeOverview ? rangeLabel : day.date.formatted(.dateTime.day().month(.wide)))
                        .scaledFont(13, maxScale: 1.25).foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 0)
                if selectedDateIsInPlan {
                    NavigationLink {
                        FirstWeekView(initialDay: selectedDay, backTitle: "Progress")
                    } label: {
                        Label("Plan", systemImage: "plus")
                            .scaledFont(14, weight: .medium, maxScale: 1.2)
                            .padding(.horizontal, 16).frame(height: 44)
                            .gatherGlass(in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Plan \(WeeklyPlan.fullDayNames[WeeklyPlan.dayNames.firstIndex(of: selectedDay)!])")
                }
            }
            HStack(alignment: .top, spacing: 10) {
                dayStatistic(LearningProgress.duration(detail.plannedMinutes), caption: "Planned")
                dayStatistic("\(detail.completed.count) / \(detail.activities.count)", caption: "Activities")
                dayStatistic(LearningProgress.duration(detail.remainingMinutes), caption: "Left to explore")
            }
            Divider().overlay(Color.adaptive(0xEEEEEE, 0x303033))
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

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Subject progress").sectionTitle()
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(ProgressPalette.purple)
                }
                Text("Pick a card. Explore your week.")
                    .scaledFont(13, maxScale: 1.25).foregroundStyle(Theme.muted)
            }
            ForEach(Array(progress.subjects.enumerated()), id: \.element.id) { index, subject in
                SubjectLearningCard(subject: subject, index: index, selectedDate: day.date,
                    isExpanded: Binding(
                        get: { expandedSubjectID == subject.id },
                        set: { expandedSubjectID = $0 ? subject.id : nil }),
                    onToggleActivity: toggleActivity)
                    .id(subject.id)
            }
            if progress.subjects.isEmpty {
                Text("Your selected subjects will appear here when you build your weekly plan.").caption()
            }
        }
    }

    private func toggleActivity(_ activity: WeekActivity) {
        var updated = plan
        guard let index = updated.activities.firstIndex(where: { $0.id == activity.id }) else { return }
        let completing = !updated.activities[index].isDone
        withAnimation(selectionMotion) {
            updated.activities[index].isDone.toggle()
            state.saveWeek(updated, for: child.id)
            if completing { completionFeedback += 1 }
        }
        let activityDay = updated.day(for: activity.date)
        if completing && updated.remainingActivities(on: activityDay).isEmpty {
            withAnimation(.easeOut(duration: 0.2)) {
                state.dailyWrapUp = updated.learningSummary(on: activityDay, childName: child.displayName)
            }
        }
    }

}

enum ProgressPalette {
    static let background = Color.adaptive(0xE6DEFF, 0x19151F)
    static let purple = Color.adaptive(0x4430A5, 0xBBA4FF)
    static let logged = Color.adaptive(0xA99BC9, 0x75668F)
}
