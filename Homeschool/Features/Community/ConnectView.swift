import SwiftUI

/// A parent's profile. The Connect button stays at the bottom while the page scrolls.
struct ConnectView: View {
    @Environment(AppState.self) private var state
    let parent: Parent
    /// True when a parent looks at their own profile from Profile. There is nothing to connect to.
    var isPreview = false

    private var requested: Bool { state.requestedParents.contains(parent.id) }

    private var myInterests: Set<String> {
        state.children.reduce(into: Set<String>()) { $0.formUnion($1.interests) }
    }

    private var sharedInterests: [String] { parent.interests.filter { myInterests.contains($0) } }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                introduction

                VStack(alignment: .leading, spacing: 14) {
                    if !parent.children.isEmpty { meetCard }
                    if !parent.interests.isEmpty {
                        infoCard(sharedInterests.isEmpty ? "Their interests" : "Interests we share",
                                 sharedInterests.isEmpty ? parent.interests : sharedInterests)
                    }
                    if !parent.lookingFor.isEmpty {
                        infoCard("Looking to connect for", parent.lookingFor)
                    }

                    Label("Only approximate distance is shared. Your exact location stays private.",
                          systemImage: "checkmark.shield")
                        .scaledFont(14, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
        .scrollNavigationTitle(parent.name)
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !isPreview { connectBar }
        }
    }

    // White top part: who they are and a short introduction.
    private var introduction: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 20) {
                ParentAvatar(parent: parent, size: 96)
                VStack(alignment: .leading, spacing: 4) {
                    Text(parent.name)
                        .scaledFont(30, weight: .bold, maxScale: 1.15)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text(parent.role)
                        .scaledFont(17, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                    if parent.distanceKm > 0 {
                        Text("\(parent.distanceKm.formatted(.number.precision(.fractionLength(1)))) km away")
                            .scaledFont(15, maxScale: 1.3)
                            .foregroundStyle(Theme.ink)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("A little about us")
                    .scaledFont(21, weight: .semibold, maxScale: 1.2)
                    .foregroundStyle(Theme.ink)
                Text(introText)
                    .scaledFont(17, maxScale: 1.3)
                    .foregroundStyle(Theme.gatherText)
                    .lineSpacing(3)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }

    private var introText: String {
        let text = parent.bio.isEmpty ? parent.about : parent.bio
        return text.isEmpty ? "No introduction yet." : "“\(text)”"
    }

    private var meetCard: some View {
        let names = parent.children.map(\.name).joined(separator: " & ")
        let lines: [String]
        if parent.children.count == 1 {
            let child = parent.children[0]
            lines = [child.age > 0 ? "\(child.age) years old" : "", child.level].filter { !$0.isEmpty }
        } else {
            lines = parent.children.map { child in
                [child.name, child.age > 0 ? "\(child.age) years old" : "", child.level]
                    .filter { !$0.isEmpty }.joined(separator: " · ")
            }
        }
        return infoCard("Meet \(names)", lines)
    }

    private func infoCard(_ title: String, _ lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .scaledFont(22, weight: .semibold, maxScale: 1.2)
                .foregroundStyle(Theme.ink)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .scaledFont(17, maxScale: 1.3)
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.pink, in: .rect(cornerRadius: 28))
        .accessibilityElement(children: .combine)
    }

    private var connectBar: some View {
        VStack(spacing: 10) {
            Button(requested ? "Request sent" : "Connect") {
                state.sendRequest(to: parent)
            }
            .buttonStyle(.primaryHomeschool(isDimmed: requested))
            .disabled(requested)

            Text("Send a connection request. Chat once \(parent.firstName) accepts.")
                .scaledFont(14, maxScale: 1.3)
                .foregroundStyle(Theme.gatherText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Theme.background)
    }
}
