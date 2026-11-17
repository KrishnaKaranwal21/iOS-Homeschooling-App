import SwiftUI

// MARK: - WeekStyle

enum WeekStyle {
    static let pink = Color(hex: 0xFFC4C8)
    static let lavender = Color(hex: 0xE9E5FF)
    static let field = Color(hex: 0xF4F2FF)
    static let secondary = Color(hex: 0x817D9F)
    static let purple = Color(hex: 0x2B2859)
    static let border = Color(hex: 0xDFDDED)
    static let taskGrey = Color(hex: 0xF0EFF2)
}

// MARK: - AddLearningDayButton

/// Only unused weekdays are offered, so a seven-day routine never shows an extra add tile.
struct AddLearningDayButton: View {
    let days: [String]
    let onSelect: (String) -> Void
    private var available: [String] { WeeklyPlan.dayNames.filter { !days.contains($0) } }

    var body: some View {
        if !available.isEmpty {
            Menu {
                ForEach(available, id: \.self) { day in
                    Button(WeeklyPlan.fullDayNames[WeeklyPlan.dayNames.firstIndex(of: day)!]) { onSelect(day) }
                }
            } label: {
                VStack(spacing: 7) {
                    Image(systemName: "plus").scaledFont(22, weight: .medium)
                    Text("Add day").scaledFont(11, weight: .semibold, maxScale: 1.25)
                }
                .foregroundStyle(WeekStyle.purple)
                .frame(width: 74, height: 76)
                .background(Theme.surface.opacity(0.6), in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(WeekStyle.purple.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add a learning day")
            .accessibilityIdentifier("week.addDay")
        }
    }
}

// MARK: - ActivityRemovalNotice

struct ActivityRemovalNotice: View {
    let activity: WeekActivity
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.uturn.backward.circle").scaledFont(21)
                .foregroundStyle(WeekStyle.purple)
            VStack(alignment: .leading, spacing: 2) {
                Text("Removed from \(activity.date.formatted(.dateTime.weekday(.wide)))")
                    .scaledFont(12, weight: .semibold, maxScale: 1.25)
                Text(activity.title).scaledFont(11, maxScale: 1.25)
                    .foregroundStyle(Theme.secondary).lineLimit(1)
            }
            Spacer(minLength: 4)
            Button("Undo", action: onUndo)
                .scaledFont(14, weight: .semibold, maxScale: 1.25)
                .foregroundStyle(WeekStyle.purple).frame(minWidth: 44, minHeight: 44)
                .accessibilityIdentifier("home.undoRemoval")
        }
        .padding(.horizontal, 14).padding(.vertical, 5)
        .gatherGlass(in: RoundedRectangle(cornerRadius: 20), tint: Theme.lilac.opacity(0.6))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - View extensions

extension View {
    func weekFormCard() -> some View {
        background(Theme.surface, in: .rect(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(WeekStyle.border, lineWidth: 0.8))
    }
}
