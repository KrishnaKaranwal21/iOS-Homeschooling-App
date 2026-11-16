import SwiftUI

/// A nearby parent with their children and the connect, withdraw or message actions.
struct ParentCard: View {
    @Environment(AppState.self) private var state
    @Environment(\.openTab) private var openTab

    @State private var showWithdrawConfirmation = false

    let parent: Parent
    var highlight = false

    private var myInterests: Set<String> {
        state.children.reduce(into: Set<String>()) {
            $0.formUnion($1.interests)
        }
    }

    private var requested: Bool {
        state.requestedParents.contains(parent.id)
    }

    private var connected: Bool {
        state.connectedParents.contains(parent.id)
    }

    private var interests: [String] {
        let all = parent.interests

        return all.filter { myInterests.contains($0) }
            + all.filter { !myInterests.contains($0) }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            NavigationLink {
                ConnectView(parent: parent)
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    identityHeader
                        .padding(6)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(parent.about)
                            .scaledFont(15, maxScale: 1.3)
                            .foregroundStyle(Theme.ink)
                            .lineLimit(3)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )

                        if !interests.isEmpty {
                            FlowLayout(spacing: 6) {
                                ForEach(
                                    interests.prefix(4),
                                    id: \.self
                                ) { name in
                                    InfoChip(
                                        title: name,
                                        tint: Theme.chipFill,
                                        isCompact: true,
                                        symbol: myInterests.contains(name)
                                            ? "sparkles"
                                            : nil
                                    )
                                }

                                if interests.count > 4 {
                                    InfoChip(
                                        title: "+\(interests.count - 4)",
                                        tint: Theme.chipFill,
                                        isCompact: true
                                    )
                                }
                            }
                        }

                        if highlight {
                            Label {
                                Text("Most in common")
                                    .foregroundStyle(Theme.ink)
                            } icon: {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(Theme.gatherAccent)
                            }
                            .scaledFont(
                                12,
                                weight: .semibold,
                                maxScale: 1.3
                            )
                            .padding(.top, 1)
                        }

                        ProfileDivider()
                            .padding(.horizontal, -10)
                            .padding(.top, 2)

                        HStack {
                            Text("View profile")
                                .scaledFont(
                                    14,
                                    weight: .semibold,
                                    maxScale: 1.25
                                )
                                .foregroundStyle(Theme.gatherText)

                            Spacer()

                            Color.clear
                                .frame(width: 120, height: 44)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Theme.surface,
                    in: .rect(cornerRadius: 28)
                )
                .roundedStroke(
                    Theme.lilacBorder,
                    cornerRadius: 28
                )
                .contentShape(
                    RoundedRectangle(cornerRadius: 28)
                )
            }
            .buttonStyle(.plain)

            actionButton
                .padding(.trailing, 16)
                .padding(.bottom, 16)
        }
        .confirmationDialog(
            "Withdraw connection request?",
            isPresented: $showWithdrawConfirmation,
            titleVisibility: .visible
        ) {
            Button("Withdraw Request", role: .destructive) {
                state.withdrawRequest(to: parent)
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "Are you sure you want to withdraw your request to \(parent.name)?"
            )
        }
    }

    // MARK: Identity Header

    private var identityHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            ParentAvatar(parent: parent, size: 72)

            VStack(alignment: .leading, spacing: 5) {
                Text(parent.name)
                    .scaledFont(
                        21,
                        weight: .bold,
                        maxScale: 1.3
                    )
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                    .accessibilityAddTraits(.isHeader)

                Text(parent.role)
                    .scaledFont(14, maxScale: 1.3)
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                if !parent.place.isEmpty {
                    Label(
                        parent.place,
                        systemImage: "mappin.and.ellipse"
                    )
                    .scaledFont(13, maxScale: 1.3)
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(
            maxWidth: .infinity,
            minHeight: 104,
            alignment: .leading
        )
        .background(
            Theme.pinkLight,
            in: .rect(cornerRadius: 24)
        )
    }

    // MARK: Action Button

    @ViewBuilder
    private var actionButton: some View {
        if connected {
            Button {
                state.chats.pendingOpenID =
                    state.chats.startChat(with: parent)

                openTab(.chats)
            } label: {
                Label("Message", systemImage: "bubble.left")
                    .scaledFont(
                        15,
                        weight: .semibold,
                        maxScale: 1.25
                    )
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 20)
                    .frame(minWidth: 104, minHeight: 44)
                    .background(
                        Capsule().fill(Theme.lavender)
                    )
            }
            .buttonStyle(.plain)

        } else if requested {
            Button {
                showWithdrawConfirmation = true
            } label: {
                Text("Requested")
                    .scaledFont(
                        15,
                        weight: .semibold,
                        maxScale: 1.25
                    )
                    .foregroundStyle(Theme.gatherText)
                    .padding(.horizontal, 22)
                    .frame(minWidth: 104, minHeight: 44)
                    .background(
                        Capsule().fill(Theme.chipFill)
                    )
            }
            .buttonStyle(.plain)

        } else {
            Button {
                state.sendRequest(to: parent)
            } label: {
                Text("Connect")
                    .scaledFont(
                        15,
                        weight: .semibold,
                        maxScale: 1.25
                    )
                    .foregroundStyle(Theme.buttonText)
                    .padding(.horizontal, 22)
                    .frame(minWidth: 104, minHeight: 44)
                    .background(
                        Capsule().fill(Theme.buttonFill)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

/// A parent's photo, or their initials when there is none.
struct ParentAvatar: View {
    let parent: Parent
    var size: CGFloat = 88

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.pink)

            Text(String(parent.name.prefix(1)))
                .font(
                    .system(
                        size: size * 0.4,
                        weight: .semibold
                    )
                )
                .foregroundStyle(Theme.ink)

            if let photo = UIImage(named: parent.photoName) {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .accessibilityHidden(true)
    }
}
