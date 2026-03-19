import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ScreenshotStore
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(0)
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }

            TrendsView()
                .tag(1)
                .tabItem {
                    Label("趋势", systemImage: "chart.line.uptrend.xyaxis")
                }

            NavigationView {
                TimelineView(title: "历史")
            }
            .tag(2)
            .tabItem {
                Label("历史", systemImage: "clock")
            }

            NavigationView {
                AccountView()
            }
            .tag(3)
            .tabItem {
                Label("我的", systemImage: "person.crop.circle")
            }
        }
        .tint(DesignTokens.Colors.accent)
        .onChange(of: store.historyPreselectedTag) { _, tag in
            if tag != nil {
                selectedTab = 2
            }
        }
    }
}
