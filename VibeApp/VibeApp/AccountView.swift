import SwiftUI
import AuthenticationServices

struct AccountView: View {
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var sync: SyncSettings
    @State private var signInError: String?

    var body: some View {
        List {
            Section("账号") {
                if auth.isSignedIn {
                    Text("已登录")
                    Button("退出登录") {
                        auth.signOut()
                    }
                    .foregroundColor(.red)
                } else {
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authResult):
                                if let credential = authResult.credential as? ASAuthorizationAppleIDCredential {
                                    let userId = credential.user
                                    if !userId.isEmpty {
                                        auth.signIn(userId: userId)
                                    }
                                }
                            case .failure(let error):
                                signInError = error.localizedDescription
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 44)
                }

                if let signInError {
                    Text(signInError)
                        .foregroundColor(.red)
                }
            }

            Section("同步设置") {
                Toggle("启用 iCloud 同步（文本与结构化数据）", isOn: $sync.useCloudSync)
                Toggle("同步图片（可能包含敏感信息）", isOn: $sync.syncImages)
                    .disabled(!sync.useCloudSync)
            }
        }
        .navigationTitle("账号与同步")
    }
}
