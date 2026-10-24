import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var state

    /// The first visit shows the welcome Home. After the family has explored other tabs, the regular Home takes over.
    var body: some View {
        if state.hasSeenFirstHome {
            regularHome
        } else {
            FirstHomeView()
        }
    }

    private var regularHome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month())).font(.caption).foregroundStyle(Theme.secondary)
                ScreenHeader(title: "Hi Parent!", subtitle: "See what \(state.child.name) is learning this week.")
                WeeklyActivityCard()
                RestOfWeekSection(tasks: Array(state.tasks.filter { !$0.isDone }.prefix(3)))
                UpcomingEventsSection(events: Array(state.events.prefix(2)))
            }
            .padding()
        }
        .background(Theme.background)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu { Text(state.child.name) } label: {
                    HStack {
                        AvatarView(initials: String(state.child.name.prefix(1)), color: Theme.yellow, size: 28)
                        Text(state.child.name)
                        Image(systemName: "chevron.down")
                    }
                }
            }
        }
    }
}

private struct WeeklyActivityCard: View {
    var body: some View {
        Card(color: Theme.lavender) {
            VStack(alignment: .leading, spacing: 12) {
                HStack { Eyebrow("This week's activity"); Chip(title: "Coding", systemImage: "chevron.left.forwardslash.chevron.right"); Spacer(); Mascot(size: 64) }
                Text("It's about what is going to change").font(.title.bold())
                Text("45 mins").foregroundStyle(Theme.secondary)
                HStack {
                    PrimaryButton(title: "Start activity") {}
                    Button { } label: { Text("Swap").font(.headline).foregroundStyle(Theme.ink).padding(.horizontal, 28).frame(minHeight: 56).background(.white, in: Capsule()) }.buttonStyle(.plain)
                }
            }
        }
    }
}

private struct RestOfWeekSection: View {
    let tasks: [TaskItem]
    var body: some View {
        VStack(alignment: .leading) {
            Text("The rest of the week").font(.title3.bold())
            Card { VStack(alignment: .leading, spacing: 12) {
                ForEach(tasks) { t in
                    HStack { Image(systemName: "circle"); VStack(alignment: .leading) { Eyebrow(t.subject); Text(t.title) } }
                    if t.id != tasks.last?.id { Divider() }
                }
            } }
        }
    }
}

private struct UpcomingEventsSection: View {
    let events: [Event]
    var body: some View {
        VStack(alignment: .leading) {
            Text("Your upcoming events").font(.title3.bold())
            Card(color: Theme.yellow) { VStack(spacing: 12) {
                ForEach(events) { e in
                    HStack { Image(systemName: e.symbol); VStack(alignment: .leading) { Text(e.title).bold(); Text("\(e.day) \(e.month.capitalized), \(e.time)").font(.caption) }; Spacer(); Text("see more").font(.caption).foregroundStyle(Theme.secondary); Image(systemName: "chevron.right") }
                }
            } }
        }
    }
}
