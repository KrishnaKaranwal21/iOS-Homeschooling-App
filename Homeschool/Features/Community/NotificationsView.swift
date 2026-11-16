import SwiftUI

/// Lists connection requests, sent requests and other alerts, honouring the notification preferences.
struct NotificationsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.openTab) private var openTab

    private var sentRequests: [Parent] {
        MockData.parents.filter {
            state.requestedParents.contains($0.id)
            && !state.connectedParents.contains($0.id)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notifications")
                        .pageTitle()

                    Text("Tap one to see what it is about.")
                        .pageSubtitle()
                }

                if !sentRequests.isEmpty {
                    Text("Requests you sent")
                        .sectionTitle()
                        .padding(.top, 4)

                    ForEach(sentRequests) { parent in
                        NotificationCard(
                            symbol: "paperplane",
                            title: "Request sent to \(parent.name)",
                            detail: "You can chat once \(parent.firstName) accepts.",
                            time: "Just now",
                            isNew: false
                        )
                    }
                }

                Text("Recent")
                    .sectionTitle()
                    .padding(.top, 4)

                if state.visibleNotifications.isEmpty {
                    Text("You’re all caught up.")
                        .rowDetail()
                }

                ForEach(state.visibleNotifications) { item in
                    row(item)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollNavigationTitle("Notifications")
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .animation(
            .snappy,
            value: state.visibleNotifications.count
        )
    }

    @ViewBuilder
    private func row(_ item: AppNotification) -> some View {
        if case .connectionRequest(let parentID) = item.action,
           let parent = MockData.parents.first(
               where: { $0.id == parentID }
           ) {

            VStack(spacing: 12) {
                NavigationLink(value: parent) {
                    NotificationCard(
                        symbol: item.symbol,
                        title: item.title,
                        detail: item.detail,
                        time: item.time,
                        isNew: item.isNew,
                        showsChevron: true,
                        framed: false
                    )
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        state.markRead(item.id)
                    }
                )

                HStack(spacing: 10) {
                    Button {
                        if let chat = state.acceptRequest(
                            from: parentID
                        ) {
                            state.chats.pendingOpenID = chat
                            openTab(.chats)
                        }
                    } label: {
                        Text("Accept")
                            .scaledFont(
                                15,
                                weight: .semibold,
                                maxScale: 1.25
                            )
                            .foregroundStyle(Color.white)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 42
                            )
                            .background(
                                Capsule().fill(Theme.buttonFill)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        state.declineRequest(from: parentID)
                    } label: {
                        Text("Decline")
                            .scaledFont(
                                15,
                                weight: .semibold,
                                maxScale: 1.25
                            )
                            .foregroundStyle(Theme.ink)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 42
                            )
                            .background(
                                Capsule().fill(Theme.chipFill)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(
                Theme.surface,
                in: .rect(cornerRadius: 28)
            )
            .roundedStroke(
                Theme.lilacBorder,
                cornerRadius: 28
            )

        } else {
            Button {
                state.markRead(item.id)
                state.open(item.action, openTab: openTab)
            } label: {
                NotificationCard(
                    symbol: item.symbol,
                    title: item.title,
                    detail: item.detail,
                    time: item.time,
                    isNew: item.isNew,
                    showsChevron: item.action != .none
                )
            }
            .buttonStyle(.plain)
            .disabled(item.action == .none)
        }
    }
}

/// One row of the notifications list.
struct NotificationCard: View {
    let symbol: String
    let title: String
    let detail: String
    let time: String
    let isNew: Bool

    var showsChevron = false
    var framed = true

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .scaledFont(
                    17,
                    weight: .semibold,
                    maxScale: 1.2
                )
                .foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(Theme.lavender)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .rowTitle()
                    .multilineTextAlignment(.leading)

                Text(detail)
                    .rowDetail()
                    .multilineTextAlignment(.leading)

                Text(time)
                    .scaledFont(12, maxScale: 1.3)
                    .foregroundStyle(Theme.gatherText)
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)

            if isNew {
                Circle()
                    .fill(Theme.gatherAccent)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)
                    .accessibilityLabel("New")
            }

            if showsChevron {
                Image(systemName: "chevron.right").accessibilityHidden(true)
                    .font(
                        .system(
                            size: 12,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(Theme.dotInactive)
                    .padding(.top, 6)
            }
        }
        .padding(framed ? 14 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            framed ? Theme.surface : Color.clear,
            in: .rect(cornerRadius: 28)
        )
        .roundedStroke(
            framed ? Theme.lilacBorder : Color.clear,
            cornerRadius: 28
        )
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Notifications") {
    NotificationsView()
        .environment(AppState())
}
