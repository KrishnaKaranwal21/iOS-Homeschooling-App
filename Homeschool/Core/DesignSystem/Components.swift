import SwiftUI

struct Card<Content: View>: View {
    var color: Color = .white
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(Theme.Spacing.m).frame(maxWidth: .infinity, alignment: .leading)
            .background(color, in: .rect(cornerRadius: Theme.Radius.card))
    }
}

struct Chip: View {
    let title: String
    var systemImage: String? = nil
    var selected = false
    var body: some View {
        HStack(spacing: 6) {
            if let systemImage { Image(systemName: systemImage) }
            Text(title)
            if selected { Image(systemName: "checkmark") }
        }
        .font(.subheadline).padding(.horizontal, 14).padding(.vertical, 10)
        .background(selected ? Theme.pink : Theme.field, in: Capsule())
    }
}

struct Eyebrow: View {
    let text: String
    init(_ t: String) { text = t }
    var body: some View { Text(text.uppercased()).font(.caption2).tracking(0.8).foregroundStyle(Theme.secondary) }
}

struct ScreenHeader: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.largeTitle.bold())
            if let subtitle { Text(subtitle).foregroundStyle(Theme.secondary) }
        }
    }
}

struct Mascot: View {
    var size: CGFloat = 80
    var body: some View {
        ZStack {
            Circle().fill(Theme.coral.opacity(0.85))
            Image(systemName: "face.smiling.inverse").font(.system(size: size * 0.5)).foregroundStyle(.white)
        }.frame(width: size, height: size)
    }
}

struct AvatarView: View {
    let initials: String
    var color: Color = Theme.lavender
    var size: CGFloat = 48
    var body: some View {
        Text(initials).font(.system(size: size * 0.36, weight: .semibold))
            .frame(width: size, height: size).background(color, in: Circle())
    }
}
