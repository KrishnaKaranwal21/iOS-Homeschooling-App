import SwiftUI

/// The "Parent" tab of the profile: bio, what the parent is looking for, completeness and the community preview.
extension ProfileView {
    // MARK: Parent tab

    var bioBinding: Binding<String> {
        Binding(get: { state.account?.bio ?? "" },
                set: { state.updateCommunityProfile(bio: String($0.prefix(Self.bioLimit))) })
    }

    static let bioLimit = 240

    var lookingFor: [String] { state.account?.lookingFor ?? [] }

    func toggleLookingFor(_ option: String) {
        var current = lookingFor
        if let index = current.firstIndex(of: option) { current.remove(at: index) } else { current.append(option) }
        state.updateCommunityProfile(lookingFor: current)
    }

    /// How far the profile is filled in, and what is still missing.
    @ViewBuilder var completenessCard: some View {
        let missing = state.missingProfileItems
        if !missing.isEmpty {
            let total = 2 + 3 * max(state.children.count, 1)
            let done = max(0, total - missing.count)
            ProfileCard(symbol: "checkmark.seal", title: "Finish your profile",
                        subtitle: "\(done) of \(total) steps done") {
                VStack(alignment: .leading, spacing: 14) {
                    ProgressView(value: Double(done), total: Double(total))
                        .tint(Theme.tabSelected)
                    FlowLayout(spacing: 8) {
                        ForEach(missing, id: \.self) { InfoChip(title: $0, tint: Theme.chipFill, isCompact: true) }
                    }
                    Button {
                        let parentMissing = missing.contains("Your name") || missing.contains("Your mobile number")
                        if parentMissing { showParentEdit = true } else { goToChildren = true }
                    } label: {
                        Text("Add missing details")
                            .scaledFont(15, weight: .semibold, maxScale: 1.25)
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(Capsule().fill(Theme.lavender))
                    }
                    .buttonStyle(.plain)
                    Text("These are needed before you can host an event.")
                        .scaledFont(13, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                }
            }
        }
    }

    var parentTab: some View {
        VStack(spacing: 18) {
            ProfileCard(symbol: "person.crop.circle", title: "Your details") {
                VStack(spacing: 6) {
                    Button { showParentEdit = true } label: {
                        ProfileInfoRow(symbol: "phone", title: "Mobile",
                                       value: (state.account?.mobile).flatMap { $0.isEmpty ? nil : $0 } ?? "Add a number")
                    }
                    .buttonStyle(.plain)
                    ProfileDivider()
                    ProfileInfoRow(symbol: "envelope", title: "Email",
                                   value: state.account?.email ?? "Not set", showsChevron: false)
                }
            }

            ProfileCard(symbol: "text.quote", title: "A little about us",
                        subtitle: "Shown on your community profile") {
                VStack(alignment: .trailing, spacing: 6) {
                    TextField("Tell other families a little about you", text: bioBinding, axis: .vertical)
                        .lineLimit(3...8)
                        .scaledFont(16, maxScale: 1.3)
                        .foregroundStyle(Theme.ink)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.lilac, in: .rect(cornerRadius: 18))
                    Text("\((state.account?.bio ?? "").count)/\(Self.bioLimit)")
                        .scaledFont(12, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                        .padding(.trailing, 4)
                }
            }

            ProfileCard(symbol: "person.2.wave.2", title: "Looking to connect for",
                        subtitle: "Pick as many as you like") {
                FlowLayout(spacing: 8) {
                    ForEach(CommunityOptions.lookingFor, id: \.self) { option in
                        SelectableChip(title: option, isOn: lookingFor.contains(option)) {
                            toggleLookingFor(option)
                        }
                    }
                }
            }

            previewCard
        }
    }

    /// Opens the profile as another parent sees it.
    var previewCard: some View {
        NavigationLink {
            ConnectView(parent: communityPreview, isPreview: true)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("See how other parents see you")
                        .scaledFont(18, weight: .bold, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)
                    Text("Check what other families see.")
                        .scaledFont(14, maxScale: 1.3)
                        .foregroundStyle(Theme.ink.opacity(0.65))
                        .multilineTextAlignment(.leading)
                    Label("Preview", systemImage: "eye")
                        .scaledFont(14, weight: .semibold, maxScale: 1.2)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 16)
                        .frame(height: 38)
                        .background(Capsule().fill(Theme.buttonFill))
                        .padding(.top, 4)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").accessibilityHidden(true)
                    .scaledFont(13, weight: .semibold)
                    .foregroundStyle(Theme.gatherText)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.lilac, in: .rect(cornerRadius: 26))
            .roundedStroke(Theme.lilacBorder, cornerRadius: 26)
        }
        .buttonStyle(.plain)
    }

    /// The profile as another parent would see it.
    var communityPreview: Parent {
        let kids = state.children.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let interests = CommunityOptions.interests.filter { name in kids.contains { $0.interests.contains(name) } }
        let levels = Dictionary(uniqueKeysWithValues: kids.map { ($0.id, $0.level.isEmpty ? "" : levelText($0)) })
        return Parent(
            name: parentName, role: kids.isEmpty ? "Parent" : "Parent to " + kids.map(\.name).joined(separator: " & "),
            tags: "", distanceKm: 0, about: "", bio: state.account?.bio ?? "",
            children: kids.map { child in
                ParentChild(name: child.name,
                            age: child.birthDate.map { AgeRules.age(of: $0, on: .now) } ?? 0,
                            level: levels[child.id] ?? "",
                            interests: CommunityOptions.interests.filter { child.interests.contains($0) })
            },
            interests: interests, lookingFor: lookingFor, place: state.homeLocation.name)
    }
}
