import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }
            NavigationStack { ProgressDashboardView() }
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
            NavigationStack { GatherView() }
                .tabItem { Label("Gather", systemImage: "calendar") }
            NavigationStack { CommunityView() }
                .tabItem { Label("Community", systemImage: "person.3.fill") }
            NavigationStack { ChatsListView() }
                .tabItem { Label("Chats", systemImage: "bubble.left") }
        }
    }
}
