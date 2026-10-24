import SwiftUI

struct OnboardingPage: Identifiable {
    enum Kind { case roadmap, community, inspiration }

    let id = UUID()
    let kind: Kind
    let title: String
    let subtitle: String
    /// Optional small line under the subtitle (the community page has one).
    let footnote: String?
    let footnoteIcon: String?

    static let all: [OnboardingPage] = [
        .init(kind: .roadmap,
              title: "Less guessing.\nMore growing.",
              subtitle: "A schedule shaped around your child and their interests, a week that works for you.",
              footnote: nil,
              footnoteIcon: nil),
        .init(kind: .community,
              title: "Your people.\nYour kind of liking.",
              subtitle: "Find nearby parents, start a chat,\nand turn shared interests into playdates.",
              footnote: "Your area is visible. Your address isn’t.",
              footnoteIcon: "lock"),
        .init(kind: .inspiration,
              title: "You don’t have to\ndo it all.",
              subtitle: "Find classes and workshops nearby.\nOr bring your own community together.",
              footnote: nil,
              footnoteIcon: nil)
    ]
}
