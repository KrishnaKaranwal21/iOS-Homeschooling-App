import SwiftUI

/// A parent's community profile. It uses the same hero and cards as the family's own Profile.
/// The Connect button stays at the bottom while the page scrolls.
struct ConnectView: View {
    @Environment(AppState.self) private var state
    let parent: Parent
    /// True when a parent looks at their own profile from Profile. There is nothing to connect to.
    var isPreview = false

    private let tileColors: [Color] = [Theme.lavender, Theme.yellow, Theme.lime, Theme.pink]

    private var requested: Bool { state.requestedParents.contains(parent.id) }

    private var myInterests: Set<String> {
        state.children.reduce(into: Set<String>()) { $0.formUnion($1.interests) }
    }

    private var sharedInterests: [String] { parent.interests.filter { myInterests.contains($0) } }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if isPreview { previewBanner }

                ProfileHero(initial: String(parent.name.prefix(1)).uppercased(),
                            photoName: parent.photoName,
                            title: parent.name,
                            subtitle: parent.role,
                            chips: heroChips)

                ProfileCard(symbol: "text.quote", title: "A little about us") {
                    Text(introText)
                        .scaledFont(17, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                        .lineSpacing(4)
                }

                if !parent.children.isEmpty { meetCard }

                if !parent.interests.isEmpty { interestsCard }

                if !parent.lookingFor.isEmpty {
                    ProfileCard(symbol: "person.2.wave.2", title: "Looking to connect for") {
                        FlowLayout(spacing: 8) {
                            ForEach(parent.lookingFor, id: \.self) { InfoChip(title: $0, tint: Theme.pink) }
                        }
                    }
                }

                HStack(spacing: 12) {
                    Image(systemName: "checkmark.shield")
                        .font(.title3)
                        .foregroundStyle(Theme.gatherAccent)
                    Text("Only approximate distance is shared. Your exact location stays private.")
                        .scaledFont(14, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                }
                .padding(.horizontal, 6)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollNavigationTitle(parent.name)
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !isPreview { connectBar }
        }
    }

    // MARK: Pieces

    private var previewBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye")
                .foregroundStyle(Theme.gatherAccent)
            Text("This is how other parents see your profile.")
                .scaledFont(14, weight: .medium, maxScale: 1.3)
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Theme.lilac, in: .rect(cornerRadius: 18))
    }

    private var heroChips: [ProfileHeroChip] {
        var chips: [ProfileHeroChip] = []
        if parent.distanceKm > 0 {
            chips.append(ProfileHeroChip(symbol: "mappin.and.ellipse", text: "\(parent.approxDistance) away"))
        }
        if !isPreview, !sharedInterests.isEmpty {
            chips.append(ProfileHeroChip(symbol: "sparkles",
                                         text: sharedInterests.count == 1 ? "1 shared interest" : "\(sharedInterests.count) shared interests"))
        }
        if parent.children.count > 0 {
            chips.append(ProfileHeroChip(symbol: "person.2.fill",
                                         text: parent.children.count == 1 ? "1 child" : "\(parent.children.count) children"))
        }
        return chips
    }

    private var introText: String {
        let text = parent.bio.isEmpty ? parent.about : parent.bio
        return text.isEmpty ? "No introduction yet." : "“\(text)”"
    }

    private var meetCard: some View {
        let names = parent.children.map(\.name).joined(separator: " & ")
        return ProfileCard(symbol: "face.smiling", title: "Meet \(names)") {
            VStack(spacing: 10) {
                ForEach(Array(parent.children.enumerated()), id: \.offset) { index, child in
                    HStack(spacing: 14) {
                        Text(String(child.name.prefix(1)).uppercased())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(tileColors[index % tileColors.count]))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(child.name)
                                .scaledFont(17, weight: .semibold, maxScale: 1.25)
                                .foregroundStyle(Theme.ink)
                            Text(detail(for: child))
                                .scaledFont(14, maxScale: 1.3)
                                .foregroundStyle(Theme.gatherText)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(Theme.lilac, in: .rect(cornerRadius: 18))
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func detail(for child: ParentChild) -> String {
        [child.age > 0 ? "\(child.age) years old" : "", child.level]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    private var interestsCard: some View {
        let shared = isPreview ? [] : sharedInterests
        return ProfileCard(symbol: "sparkles",
                           title: isPreview ? "Interests" : (shared.isEmpty ? "Their interests" : "Interests we share"),
                           subtitle: shared.isEmpty ? nil : "\(shared.count) in common") {
            FlowLayout(spacing: 8) {
                ForEach(parent.interests, id: \.self) { name in
                    InfoChip(title: name, tint: shared.contains(name) ? Theme.lavender : Theme.chipFill)
                }
            }
        }
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
        .background(.bar)
    }
}
