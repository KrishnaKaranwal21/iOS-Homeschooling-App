import SwiftUI

enum AppTab: Hashable {
    case home, progress, gather, community, chats
}

private struct OpenTabKey: EnvironmentKey {
    static let defaultValue: (AppTab) -> Void = { _ in }
}

extension EnvironmentValues {
    /// Lets any screen jump to another tab, for example a Home card opening Gather.
    var openTab: (AppTab) -> Void {
        get { self[OpenTabKey.self] }
        set { self[OpenTabKey.self] = newValue }
    }
}

/// The original system tab bar. Only the colours are customised:
/// muted purple for the current page, soft lilac icons and grey labels for the rest.
struct MainTabView: View {
    @Environment(AppState.self) private var state
    @Environment(\.displayScale) private var displayScale
    @State private var selection: AppTab = .home
    /// Changing a tab's number rebuilds it, which returns it to its first page.
    @State private var resetCounts: [AppTab: Int] = [:]

    var body: some View {
        TabView(selection: $selection) {
            Tab(value: AppTab.home) {
                NavigationStack { HomeView() }.id(resetCounts[.home, default: 0])
            } label: {
                label("Home", symbol: "house.fill", tab: .home)
            }
            Tab(value: AppTab.progress) {
                NavigationStack { ProgressDashboardView() }.id(resetCounts[.progress, default: 0])
            } label: {
                label("Progress", symbol: "chart.bar.fill", tab: .progress)
            }
            Tab(value: AppTab.gather) {
                NavigationStack { GatherView() }.id(resetCounts[.gather, default: 0])
            } label: {
                label("Gather", symbol: "calendar", tab: .gather)
            }
            Tab(value: AppTab.community) {
                NavigationStack { CommunityView() }.id(resetCounts[.community, default: 0])
            } label: {
                label("Community", symbol: "person.3.fill", tab: .community)
            }
            Tab(value: AppTab.chats) {
                NavigationStack { ChatsListView() }.id(resetCounts[.chats, default: 0])
            } label: {
                label("Chats", symbol: "bubble.left", tab: .chats)
            }
            .badge(state.chats.unreadChatCount)
        }
        .tint(Theme.tabSelected)
        .task { state.refreshLiveLocation() }
        .environment(\.openTab, { selection = $0 })
        .onChange(of: selection) { old, new in
            // Leaving Home for the first time ends the first-time Home.
            if old == .home && new != .home { state.markFirstHomeSeen() }
            // Coming back to a tab shows its first page, not the last page you had open.
            resetCounts[old, default: 0] += 1
        }
    }

    /// The icon is coloured by hand because the system draws unselected icons black on newer iOS versions.
    private func label(_ title: String, symbol: String, tab: AppTab) -> some View {
        Label {
            Text(title)
        } icon: {
            icon(symbol, isSelected: selection == tab)
        }
    }

    /// Icons are drawn into plain bitmaps so the tab bar can't swap them for another symbol variant or recolour them.
    /// `ImageRenderer` is SwiftUI's own renderer, so no UIKit is needed.
    private func icon(_ symbol: String, isSelected: Bool) -> Image {
        let color = isSelected ? Theme.tabSelected : Theme.tabIconInactive
        let renderer = ImageRenderer(content:
            Image(systemName: symbol)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(color)
                .padding(2))
        renderer.scale = displayScale
        guard let bitmap = renderer.cgImage else { return Image(systemName: symbol) }
        return Image(decorative: bitmap, scale: displayScale).renderingMode(.original)
    }
}
