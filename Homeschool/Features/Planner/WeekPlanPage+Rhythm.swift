import SwiftUI

/// The week strip: the days of the week with their planned minutes.
extension WeekPlanPage {
    var rhythm: some View {
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

    /// Day tiles for the planner sheet: white tiles with a coral outline when selected, exactly like Home.
    var plannerRhythm: some View {
        GeometryReader { geometry in
            let count = CGFloat(max(1, plan.days.count))
            let width = plan.days.count <= 4 ? min(82, max(48, (geometry.size.width - (count - 1) * 6 - 6) / count)) : 74
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(Array(plan.days.enumerated()), id: \.element) { index, day in
                            let selected = selectedDay == day
                            Button { selectedDay = day } label: {
                                VStack(spacing: 6) {
                                    Text(day.uppercased()).scaledFont(17, weight: .heavy, maxScale: 1.15)
                                    Capsule().fill(Color(hex: 0xF0959F)).frame(width: 22, height: 5)
                                    Text(LearningProgress.duration(plan.minutes(on: day)))
                                        .scaledFont(14, weight: .medium, maxScale: 1.2)
                                        .foregroundStyle(Theme.secondary).lineLimit(1).minimumScaleFactor(0.65)
                                }
                                .frame(width: width, height: 76)
                                .background(Theme.surface, in: .rect(cornerRadius: 14))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(selected ? Color(hex: 0xB46759).opacity(0.85) : .clear, lineWidth: 1.25)
                                }
                                .shadow(color: Color(hex: 0xB46759).opacity(selected ? 0.08 : 0), radius: 4, y: 2)
                                .rotationEffect(.degrees([-3, 2, -2, 3][index % 4]))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(WeeklyPlan.fullDayNames[WeeklyPlan.dayNames.firstIndex(of: day)!]), \(LearningProgress.duration(plan.minutes(on: day))) planned")
                            .accessibilityAddTraits(selected ? .isSelected : [])
                            .id(day)
                        }
                        AddLearningDayButton(days: plan.days) { day in
                            guard let date = state.addLearningDay(day, for: child.id),
                                  let updated = state.weeklyPlans[child.id.uuidString] else { return }
                            plan = updated
                            selectedDay = plan.day(for: date)
                        }
                    }
                    .padding(.horizontal, 3).padding(.vertical, 7)
                }
                .scrollIndicators(.hidden)
                .onAppear { proxy.scrollTo(selectedDay, anchor: .center) }
                .onChange(of: selectedDay) { _, day in
                    withAnimation(reduceMotion ? nil : rowAnimation) { proxy.scrollTo(day, anchor: .center) }
                }
            }
        }
        .frame(height: 90)
    }
}
