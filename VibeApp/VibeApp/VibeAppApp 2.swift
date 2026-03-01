import SwiftUI

@main
struct VibeAppApp: App {
    @StateObject private var store = ScreenshotStore()
    @StateObject private var auth = AuthStore()
    @StateObject private var sync = SyncSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(auth)
                .environmentObject(sync)
        }
    }
}
