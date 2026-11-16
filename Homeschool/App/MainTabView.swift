import SwiftUI

// MARK: - AppTab

enum AppTab: Hashable {
    case home, progress, gather, community, chats
}

// MARK: - OpenTabKey

struct OpenTabKey: EnvironmentKey {
    static let defaultValue: (AppTab) -> Void = { _ in }
}

// MARK: - EnvironmentValues extensions

extension EnvironmentValues {
    /// Lets any screen jump to another tab, for example a Home card opening Gather.
    var openTab: (AppTab) -> Void {
        get { self[OpenTabKey.self] }
        set { self[OpenTabKey.self] = newValue }
    }
}

// MARK: - MainTabView

/// The system tab bar: a bottom bar on iPhone and the floating bar at the top on iPad.
/// Only the colours are customised: muted purple for the current page, and a softer purple for the rest.
struct MainTabView: View {
    @Environment(AppState.self) private var state
    @Environment(\.displayScale) private var displayScale
    @State private var selection: AppTab = .home
    /// Changing a tab's number rebuilds it, which returns it to its first page.
    @State private var resetCounts: [AppTab: Int] = [:]

    var body: some View {
        @Bindable var bindableState = state
        return TabView(selection: $selection) {
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
                NavigationStack(path: $bindableState.gatherPath) { GatherView() }
                    .toolbarVisibility(state.hidesTabBar ? .hidden : .automatic, for: .tabBar)
                    .id(resetCounts[.gather, default: 0])
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
        .allowsHitTesting(state.dailyWrapUp == nil)
        .accessibilityHidden(state.dailyWrapUp != nil)
        .overlay {
            if let summary = state.dailyWrapUp {
                DailyWrapUpView(summary: summary) {
                    withAnimation(.easeOut(duration: 0.2)) { state.dailyWrapUp = nil }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .tint(Theme.tabSelected)
        .task { state.refreshLiveLocation() }
        .environment(\.openTab, { selection = $0 })
        .overlay {
            if let popup = state.popup {
                AppPopupView(popup: popup) {
                    state.popup = nil
                } onOpen: {
                    state.popup = nil
                    state.open(popup.action) { selection = $0 }
                }
                .transition(.opacity)
            }
        }
        .animation(.snappy, value: state.popup?.id)
        .onChange(of: selection) { old, new in
            // An event opened from a notification shouldn't stay open once you leave Gatherings.
            if old == .gather { state.gatherPath = NavigationPath() }
            // Records the first Home visit; returning-session routing is decided separately when logging in or
            // restoring the app.
            if old == .home && new != .home { state.markFirstHomeSeen() }
            // Coming back to a tab shows its first page, not the last page you had open.
            resetCounts[old, default: 0] += 1
        }
    }

    /// The icon is coloured by hand because the system draws unselected icons black on newer iOS versions.
    /// The title colour is set too; the system uses it where it allows.
    private func label(_ title: String, symbol: String, tab: AppTab) -> some View {
        Label {
            Text(title)
                .foregroundStyle(selection == tab ? Theme.tabSelected : Theme.tabUnselectedLabel)
        } icon: {
            icon(symbol, isSelected: selection == tab)
        }
    }

    /// Icons are drawn into plain bitmaps so the tab bar can't swap them for another symbol variant or recolour them.
    /// `ImageRenderer` is SwiftUI's own renderer, so no UIKit is needed.
    private func icon(_ symbol: String, isSelected: Bool) -> Image {
        let color = isSelected ? Theme.tabSelected : Theme.tabUnselectedIcon
        let renderer = ImageRenderer(content:
            Image(systemName: symbol)
                .scaledFont(21, weight: .semibold)
                .foregroundStyle(color)
                .environment(\.colorScheme, .light)
                .padding(2))
        renderer.scale = displayScale
        guard let bitmap = renderer.cgImage else { return Image(systemName: symbol) }
        return Image(decorative: bitmap, scale: displayScale).renderingMode(.original)
    }
}

#Preview("Main tabs") {
    MainTabView()
        .environment(AppState())
}
