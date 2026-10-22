import SwiftUI

struct OnboardingPage: Identifiable {
    enum Kind { case roadmap, community, inspiration }

    let id = UUID()
    let kind: Kind
    let title: String
    let subtitle: String
    let footnote: String
    let footnoteIcon: String?

    static let all: [OnboardingPage] = [
        .init(kind: .roadmap,
              title: "Less guessing.\nMore growing.",
              subtitle: "A roadmap shaped around your child.\nA week that works for you.",
              footnote: "Your direction. Always adjustable.",
              footnoteIcon: nil),
        .init(kind: .community,
              title: "Your people.\nYour kind of liking.",
              subtitle: "Find nearby parents, start a chat,\nand turn shared interests into playdates.",
              footnote: "Your area is visible. Your address isn’t.",
              footnoteIcon: "lock"),
        .init(kind: .inspiration,
              title: "You don’t have to\ndo it all.",
              subtitle: "Find classes and workshops nearby.\nOr bring your own community together.",
              footnote: "A circle of support, beyond your schedule.",
              footnoteIcon: nil)
    ]
}
