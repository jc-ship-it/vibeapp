import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house")
                }

            TrendsView()
                .tabItem {
                    Label("趋势", systemImage: "chart.line.uptrend.xyaxis")
                }

            NavigationView {
                TimelineView(title: "历史")
            }
            .tabItem {
                Label("历史", systemImage: "clock.arrow.circlepath")
            }

            NavigationView {
                AccountView()
            }
            .tabItem {
                Label("我的", systemImage: "person.crop.circle")
            }
        }
    }
}
