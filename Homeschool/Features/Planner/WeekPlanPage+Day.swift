import SwiftUI

/// The selected day: heading, activity rows, the add button, the empty state and completed tasks.
extension WeekPlanPage {
    var dayHeading: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(isSheet ? "Your activities" : WeeklyPlan.fullDayNames[dayIndex]).sectionTitle()
            }
            Text(Self.duration(dailyMinutes) + " learning" + (completed.isEmpty ? "" : " · \(remaining.count) left"))
                .scaledFont(14, maxScale: 1.2).foregroundStyle(WeekStyle.secondary)
        }
    }

    func activityRow(_ activity: WeekActivity) -> some View {
        let subjectIndex = child.subjectNames.firstIndex { LearningProgress.subjectKey($0) == LearningProgress.subjectKey(activity.subject) } ?? 0
        let palette = SubjectCardPalette.all[subjectIndex % SubjectCardPalette.all.count]
        return HStack(spacing: 0) {
            Button {
                taskEditor = TaskEditorRequest(activity: activity, isEditing: true)
            } label: {
                HStack(spacing: 10) {
                    Text("\(activity.minutes) min")
                        .scaledFont(14, weight: .medium, maxScale: 1.2)
                        .foregroundStyle(isSheet ? palette.ink : (activity.subject.lowercased().contains("math") ? Color(hex: 0x8D4540) : WeekStyle.purple))
                        .frame(width: 62, height: 32)
                        .background(isSheet ? palette.paper : (activity.subject.lowercased().contains("math") ? WeekStyle.pink : Theme.field), in: Capsule())
                        .overlay { if isSheet { Capsule().strokeBorder(palette.ink.opacity(0.14), lineWidth: 0.8) } }
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
                    Image(systemName: "ellipsis").scaledFont(18, weight: .semibold)
                        .foregroundStyle(palette.ink).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Options for \(activity.title)")
            } else {
            Button { complete(activity) } label: {
                Image(systemName: "checkmark")
                    .scaledFont(16, weight: .semibold)
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
                    .scaledFont(19, weight: .regular)
                    .foregroundStyle(Color(hex: 0x9C6C73))
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
        .background(isSheet ? WeekStyle.taskGrey : Theme.surface, in: .rect(cornerRadius: isSheet ? 20 : 11))
        .overlay(RoundedRectangle(cornerRadius: isSheet ? 20 : 11).strokeBorder(isSheet ? Theme.surface : WeekStyle.border, lineWidth: 0.8))
    }

    var footer: some View {
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
                    Text("Add a task")
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
                        .scaledFont(24, weight: .medium)
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

    var dayEmptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: completed.isEmpty ? "leaf" : "checkmark.seal.fill")
                .scaledFont(30, weight: .light)
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

    var completedSection: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(rowAnimation) { showCompleted.toggle() }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark.seal")
                    Text("\(completed.count) completed · \(completed.reduce(0) { $0 + $1.minutes }) min logged")
                        .scaledFont(12, weight: .medium, maxScale: 1.2)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down").accessibilityHidden(true)
                        .scaledFont(10, weight: .semibold)
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
}
