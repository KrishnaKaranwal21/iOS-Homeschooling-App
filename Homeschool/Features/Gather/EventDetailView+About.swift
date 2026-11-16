import SwiftUI

/// The organizer, description and report sections of an event page.
extension EventDetailView {
    var organizerCard: some View {
        HStack(spacing: 16) {
            Text(initials(current.host))
                .scaledFont(20, weight: .bold, maxScale: 1.2).foregroundStyle(Theme.ink)
                .frame(width: 52, height: 52).background(Theme.lavender, in: .rect(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 5) {
                Text(current.host).scaledFont(16, weight: .bold, maxScale: 1.3).foregroundStyle(Theme.ink)
                Text(current.isHostedByMe ? "You’re organizing this event" : current.hostRole)
                    .scaledFont(13, maxScale: 1.3).foregroundStyle(Theme.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.field, in: .rect(cornerRadius: 26))
        .accessibilityElement(children: .combine)
    }

    var descriptionText: some View {
        let content = (try? AttributedString(markdown: current.about,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(current.about)
        return Text(content).scaledFont(16, maxScale: 1.35)
            .foregroundStyle(Theme.secondary).lineSpacing(5)
    }

    var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            descriptionText
                .lineLimit(expandedAbout ? nil : 6)
                .fixedSize(horizontal: false, vertical: true)
                .background(alignment: .topLeading) {
                    descriptionText.lineLimit(nil).fixedSize(horizontal: false, vertical: true)
                        .hidden().accessibilityHidden(true)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { descriptionFullHeight = $0 }
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                    if !expandedAbout { descriptionPreviewHeight = $0 }
                }
            if expandedAbout || descriptionFullHeight > descriptionPreviewHeight + 1 {
                Button(expandedAbout ? "Read less" : "Read more") {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { expandedAbout.toggle() }
                }
                .scaledFont(16, weight: .semibold, maxScale: 1.3)
                .foregroundStyle(Theme.accent).buttonStyle(.plain)
                .accessibilityIdentifier("event.readMore")
            }
            Text(current.normalizedCategory).scaledFont(13, weight: .semibold, maxScale: 1.25)
                .foregroundStyle(Theme.ink).padding(.horizontal, 14).padding(.vertical, 7)
                .roundedStroke(Theme.cardBorder, cornerRadius: 18)
        }
    }

    var reportButton: some View {
        Button { showReport = true } label: {
            HStack(spacing: 16) {
                Image(systemName: "flag")
                    .scaledFont(20, weight: .semibold, maxScale: 1.2).foregroundStyle(Theme.ink)
                    .frame(width: 52, height: 52).background(Theme.lavender, in: .rect(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 5) {
                    Text("Report this event").scaledFont(16, weight: .bold, maxScale: 1.3).foregroundStyle(Theme.ink)
                    Text("Tell us if something isn’t right")
                        .scaledFont(13, maxScale: 1.3).foregroundStyle(Theme.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").accessibilityHidden(true).scaledFont(12, weight: .semibold).foregroundStyle(Theme.secondary)
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.field, in: .rect(cornerRadius: 26))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("event.report")
    }
}
