import SwiftUI

/// The Syllabus tab: the selected child's subjects with how much of each is covered.
struct SyllabusDashboardView: View {
    @Environment(AppState.self) private var state
    @State private var showAddChild = false
    private var subjects: [SyllabusSubject] { MockData.syllabus(for: state.child) }
    private var progress: SyllabusProgress { SyllabusProgress(plans: state.learningPlans(for: state.child.id)) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Text("Syllabus").pageTitle()
                    Spacer()
                    ChildSwitcherMenu(onAddChild: { showAddChild = true }) {
                        HStack(spacing: 7) {
                            AvatarView(initials: String(state.child.displayName.prefix(1)), size: 28)
                            Text(state.child.displayName).font(.subheadline.weight(.medium)).lineLimit(1)
                            Image(systemName: "chevron.down").accessibilityHidden(true).font(.caption)
                        }
                        .padding(9).gatherGlass(in: Capsule(), tint: Theme.lavender.opacity(0.25))
                    }
                }
                if subjects.isEmpty {
                    ContentUnavailableView("Choose a NIOS level", systemImage: "books.vertical",
                        description: Text("Your child’s level and chosen subjects determine the syllabus. Choose them in your child’s learning profile."))
                } else {
                    ForEach(Array(subjects.enumerated()), id: \.element.id) { index, subject in
                        NavigationLink {
                            SyllabusSubjectView(subject: subject, childID: state.child.id, paletteIndex: index)
                        } label: {
                            subjectCard(subject, index: index)
                        }.buttonStyle(.plain)
                    }
                }
                Text("Sources checked 17 Nov 2026 · Available offline")
                    .font(.caption2).foregroundStyle(Theme.secondary)
            }
            .padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .scrollNavigationTitle("Syllabus")
        .toolbarVisibility(.visible, for: .navigationBar)
        .fullScreenCover(isPresented: $showAddChild) { AddChildFlow() }
        .onAppear { state.prepareHomeWeek(for: state.child.id) }
        .onChange(of: state.child.id) { _, id in state.prepareHomeWeek(for: id) }
    }

    private func subjectCard(_ subject: SyllabusSubject, index: Int) -> some View {
        let palette = SubjectCardPalette.all[index % SubjectCardPalette.all.count]
        let done = progress.count(.completed, in: subject)
        let planned = progress.count(.planned, in: subject)
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: SubjectCardPalette.symbol(for: subject.name))
                    .font(.title2).foregroundStyle(palette.ink).frame(width: 46, height: 46)
                    .background(.white.opacity(0.8), in: .rect(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.name).font(.title3.bold()).multilineTextAlignment(.leading)
                    Text(subject.hasOutline ? "\(subject.chapters.count) \(subject.chapters.allSatisfy { $0.kind == "competency" } ? "learning areas" : "chapters") · \(subject.topics.count) topics" : "Official materials")
                        .font(.caption).foregroundStyle(Theme.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").accessibilityHidden(true).font(.subheadline.weight(.semibold)).foregroundStyle(palette.ink)
            }
            if subject.hasOutline {
                ProgressView(value: Double(done), total: Double(max(1, subject.topics.count))).tint(palette.ink)
                HStack {
                    Label("\(done) completed", systemImage: "checkmark.circle")
                    Spacer()
                    Text("\(planned) this week")
                }.font(.caption.weight(.medium)).foregroundStyle(palette.ink)
            } else {
                Text("View the NIOS source and outline availability.").font(.footnote).foregroundStyle(palette.ink)
            }
        }
        .padding(20).background(palette.paper, in: .rect(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(.white, lineWidth: 1.5))
        .accessibilityElement(children: .combine)
    }
}

#Preview("Syllabus") {
    SyllabusDashboardView()
        .environment(AppState())
}
