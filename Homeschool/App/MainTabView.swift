import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                NavigationStack { HomeView() }
            }
            Tab("Progress", systemImage: "chart.bar.fill") {
                NavigationStack { ProgressDashboardView() }
            }
            Tab("Gather", systemImage: "calendar") {
                NavigationStack { GatherView() }
            }
            Tab("Community", systemImage: "person.3.fill") {
                NavigationStack { CommunityView() }
            }
            Tab("Chats", systemImage: "bubble.left") {
                NavigationStack { ChatsListView() }
            }
        }
    }
}
