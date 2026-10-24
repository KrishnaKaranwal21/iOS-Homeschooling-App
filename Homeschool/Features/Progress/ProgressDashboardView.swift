import SwiftUI

struct ProgressDashboardView: View {
    @Environment(AppState.self) private var state
    @State private var day = "Mon"
    private let days = ["Mon", "Tue", "Thu", "Fri"]
    private var done: [TaskItem] { state.tasks.filter(\.isDone) }
    private var left: [TaskItem] { state.tasks.filter { !$0.isDone } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Daily progress").font(.largeTitle.bold())
                Picker("Day", selection: $day) { ForEach(days, id: \.self, content: Text.init) }.pickerStyle(.segmented)
                summary
                TaskSection(title: "Tasks Left", tasks: left, color: .white) { state.toggle($0) }
                TaskSection(title: "Tasks Completed", tasks: done, color: Theme.field) { state.toggle($0) }
                NavigationLink { RoadmapOverviewView() } label: {
                    PrimaryButtonLabel(title: "Build your Roadmap")
                }
                .buttonStyle(.plain)
            }.padding()
        }.background(Theme.background)
    }

    private var summary: some View {
        Card(color: Theme.pink) {
            VStack(alignment: .leading, spacing: 8) {
                HStack { VStack(alignment: .leading) { Eyebrow("\(day)day's learning"); Text("\(done.count) of \(state.tasks.count)").scaledFont(56, weight: .bold); Text("tasks completed").font(.footnote) }; Spacer(); Mascot(size: 72) }
                ProgressView(value: Double(done.count), total: Double(max(state.tasks.count, 1))).tint(Theme.ink)
                Text("3 hrs logged").font(.headline).frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

private struct TaskSection: View {
    let title: String, tasks: [TaskItem], color: Color
    let toggle: (TaskItem) -> Void
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.title3.bold())
            Card(color: color) { VStack(alignment: .leading, spacing: 12) {
                ForEach(tasks) { t in
                    Button { toggle(t) } label: {
                        HStack(alignment: .top) { Image(systemName: t.isDone ? "checkmark.circle" : "circle").font(.title3); VStack(alignment: .leading) { Eyebrow(t.subject); Text(t.title).multilineTextAlignment(.leading) } }
                    }.buttonStyle(.plain)
                    if t.id != tasks.last?.id { Divider() }
                }
            } }
        }
    }
}
