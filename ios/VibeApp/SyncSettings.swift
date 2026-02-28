import Foundation

final class SyncSettings: ObservableObject {
    @Published var useCloudSync: Bool {
        didSet { UserDefaults.standard.set(useCloudSync, forKey: "vibeapp_cloud_sync") }
    }

    @Published var syncImages: Bool {
        didSet { UserDefaults.standard.set(syncImages, forKey: "vibeapp_sync_images") }
    }

    init() {
        useCloudSync = UserDefaults.standard.bool(forKey: "vibeapp_cloud_sync")
        syncImages = UserDefaults.standard.bool(forKey: "vibeapp_sync_images")
    }
}
