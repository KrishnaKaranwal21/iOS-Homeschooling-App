import SwiftUI

struct RoadmapOverviewView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(title: "Your Roadmap", subtitle: "Everything you need to get started, one step at a time.")
                Card(color: Theme.pink) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Let's start your homeschooling journey").font(.title3.bold())
                        Text("We'll guide you from homeschooling basics to a suitable routine for \(state.child.name).")
                        NavigationLink("Continue learning") { RoadmapArticleView() }
                            .buttonStyle(.borderedProminent).controlSize(.large)
                    }
                }
                ForEach(MockData.roadmap) { step in
                    NavigationLink { RoadmapDetailView(step: step) } label: {
                        Card { HStack(spacing: 12) {
                            Text(step.id, format: .number.precision(.integerLength(2...))).font(.caption.bold()).padding(8).background(Theme.pink, in: Circle())
                            Image(systemName: step.symbol)
                            VStack(alignment: .leading) { Text(step.title).font(.headline); Text(step.detail).font(.caption).foregroundStyle(Theme.secondary); Text("Not started").font(.caption2) }
                            Spacer(); Image(systemName: "chevron.right")
                        } }
                    }.buttonStyle(.plain)
                }
            }.padding()
        }.background(Theme.background).navigationTitle("Progress").navigationBarTitleDisplayMode(.inline)
    }
}

struct RoadmapDetailView: View {
    let step: RoadmapStep
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Eyebrow("Roadmap · Step \(step.id)")
                ScreenHeader(title: step.title, subtitle: step.detail)
                Card(color: Theme.lavender) {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("Four routes to investigate")
                        ForEach(["NIOS", "CBSE", "CISCE", "Cambridge IGCSE"], id: \.self) { Label($0, systemImage: "signpost.right") }
                    }
                }
                Text("Route types differ. Suitability depends on age, goals, the qualification you need and current rules.").foregroundStyle(Theme.secondary)
            }.padding()
        }.background(Theme.background).navigationBarTitleDisplayMode(.inline)
    }
}

struct RoadmapArticleView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Eyebrow("Roadmap · Learning article")
                Text("How does homeschooling work?").font(.largeTitle.bold())
                ForEach([("What is homeschooling?", "Learning outside a conventional school. A parent coordinates resources and support."),
                         ("How does it work?", "Set goals, choose resources and support practice. Review what your child understands."),
                         ("How do I choose?", "Compare the same five things. No pathway is automatically best.")], id: \.0) { h, b in
                    VStack(alignment: .leading, spacing: 4) { Text(h).font(.title3.bold()); Text(b).foregroundStyle(Theme.secondary) }
                }
            }.padding()
        }.background(Theme.background).navigationBarTitleDisplayMode(.inline)
    }
}
