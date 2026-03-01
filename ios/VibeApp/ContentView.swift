struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house")
                }

            TrendsView()
                .tabItem {
                    Label("趋势分析", systemImage: "chart.line.uptrend.xyaxis")
                }

            NavigationView {
                TimelineView(title: "历史记录")
            }
            .tabItem {
                Label("历史记录", systemImage: "clock.arrow.circlepath")
            }

            NavigationView {
                AccountView()
            }
            .tabItem {
                Label("我的账号", systemImage: "person.crop.circle")
            }
        }
    }
}
