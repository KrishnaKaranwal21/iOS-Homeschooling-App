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

/// The day planner, shown as a full screen pushed from Progress. The first-week preview remains available during setup.
struct DayPlannerSheet: View {
    @Environment(AppState.self) private var state
    var initialDay: String? = nil
    var onSelectDate: (Date) -> Void = { _ in }

    var body: some View {
        WeekPlanPage(child: state.child, savedPlan: state.weeklyPlans[state.child.id.uuidString],
                     initialDay: initialDay, backTitle: "", onAddChild: {},
                     isSheet: true, onSelectDate: onSelectDate)
            .id(state.child.id)
    }
}
