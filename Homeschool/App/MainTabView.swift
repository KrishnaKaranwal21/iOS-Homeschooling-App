import SwiftUI
import UIKit

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
    @State private var selection: AppTab = .home

    init() {
        Self.styleLabels()
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab(value: AppTab.home) {
                NavigationStack { HomeView() }
            } label: {
                label("Home", symbol: "house.fill", tab: .home)
            }
            Tab(value: AppTab.progress) {
                NavigationStack { ProgressDashboardView() }
            } label: {
                label("Progress", symbol: "chart.bar.fill", tab: .progress)
            }
            Tab(value: AppTab.gather) {
                NavigationStack { GatherView() }
            } label: {
                label("Gather", symbol: "calendar", tab: .gather)
            }
            Tab(value: AppTab.community) {
                NavigationStack { CommunityView() }
            } label: {
                label("Community", symbol: "person.3.fill", tab: .community)
            }
            Tab(value: AppTab.chats) {
                NavigationStack { ChatsListView() }
            } label: {
                label("Chats", symbol: "bubble.left", tab: .chats)
            }
        }
        .tint(Theme.tabSelected)
        .environment(\.openTab, { selection = $0 })
        .onChange(of: selection) { old, new in
            // Leaving Home for the first time ends the first-time Home.
            if old == .home && new != .home { state.markFirstHomeSeen() }
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

    private func icon(_ symbol: String, isSelected: Bool) -> Image {
        let color = UIColor(isSelected ? Theme.tabSelected : Theme.tabIconInactive)
        if let image = UIImage(systemName: symbol)?.withTintColor(color, renderingMode: .alwaysOriginal) {
            return Image(uiImage: image)
        }
        return Image(systemName: symbol)
    }

    private static func styleLabels() {
        let selected = UIColor(Theme.tabSelected)
        let icon = UIColor(Theme.tabIconInactive)
        let label = UIColor(Theme.tabLabelInactive)

        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        for item in [appearance.stackedLayoutAppearance,
                     appearance.inlineLayoutAppearance,
                     appearance.compactInlineLayoutAppearance] {
            item.normal.iconColor = icon
            item.normal.titleTextAttributes = [.foregroundColor: label]
            item.selected.iconColor = selected
            item.selected.titleTextAttributes = [.foregroundColor: selected]
        }
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = icon

        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: label], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: selected], for: .selected)
    }
}
