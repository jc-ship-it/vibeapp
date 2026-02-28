import Foundation

final class AuthStore: ObservableObject {
    @Published private(set) var userId: String?

    private let userIdKey = "vibeapp_user_id"

    init() {
        userId = UserDefaults.standard.string(forKey: userIdKey)
    }

    var isSignedIn: Bool {
        userId != nil
    }

    func signIn(userId: String) {
        self.userId = userId
        UserDefaults.standard.set(userId, forKey: userIdKey)
    }

    func signOut() {
        userId = nil
        UserDefaults.standard.removeObject(forKey: userIdKey)
    }
}
