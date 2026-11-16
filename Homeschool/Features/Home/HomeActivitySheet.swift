import SwiftUI

/// Descriptions are suggested locally; saved steps and notes remain the source of truth for a family's custom task.
struct HomeActivitySheet: View {
    @Environment(\.dismiss) private var dismiss
    let activity: WeekActivity
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var confirmDelete = false

    private var guide: ActivityGuide { .suggested(for: activity) }
    private var hasCustomSteps: Bool { !activity.smallSteps.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var hasNotes: Bool { !activity.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(activity.subject.uppercased())
                    .scaledFont(11, weight: .semibold, maxScale: 1.25)
                    .tracking(0.5).foregroundStyle(Theme.secondary)
                Spacer(minLength: 12)
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 17, weight: .medium))
                        .frame(width: 44, height: 44).gatherGlass(in: Circle(), tint: Theme.lilac.opacity(0.35))
                }
                .accessibilityLabel("Close activity")
            }
            .padding(.horizontal, 24).padding(.top, 22).padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(activity.title).detailTitle()
                        Label("\(activity.minutes) min", systemImage: "clock").bodyText()
                    }
                    Text(guide.overview).bodyText().fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: 14) {
                        Text(hasCustomSteps ? "Your steps" : "Try it step by step").cardTitle()
                        if hasCustomSteps {
                            Text(activity.smallSteps).bodyText()
                        } else {
                            ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .scaledFont(12, weight: .semibold, maxScale: 1.3)
                                        .foregroundStyle(Theme.accent)
                                        .frame(width: 26, height: 26)
                                        .background(Theme.lilac, in: Circle())
                                        .accessibilityHidden(true)
                                    Text(step).bodyText().frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(hasNotes ? "Your notes" : "What you’ll need").cardTitle()
                        Text(hasNotes ? activity.notes : guide.materials).bodyText()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 6) {
                Button {
                    onToggle()
                    dismiss()
                } label: {
                    Label(activity.isDone ? "Mark incomplete" : "Mark complete",
                          systemImage: activity.isDone ? "arrow.uturn.backward" : "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primaryHomeschool)
                .accessibilityIdentifier("home.activity.complete")

                Button { confirmDelete = true } label: {
                    Label("Delete task", systemImage: "trash")
                        .scaledFont(16, weight: .semibold, maxScale: 1.25)
                        .foregroundStyle(Theme.warmText)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("home.activity.delete")
            }
            .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 10)
            .background(Theme.background)
        }
        .confirmationDialog("Delete this task?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete task", role: .destructive) {
                onDelete()
                dismiss()
            }
            Button("Keep task", role: .cancel) {}
        } message: {
            Text("“\(activity.title)” will be removed from this day.")
        }
        .foregroundStyle(Theme.ink).background(Theme.background).buttonStyle(.plain)
    }
}
