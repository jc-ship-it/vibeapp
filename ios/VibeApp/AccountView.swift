import SwiftUI
import AuthenticationServices

struct AccountView: View {
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var sync: SyncSettings
    @State private var signInError: String?
    @AppStorage("vibeapp_openai_key") private var apiKey: String = ""
    @State private var showApiKey = false

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
                                if let credential = authResult.credential as? ASAuthorizationAppleIDCredential,
                                   let userId = credential.user {
                                    auth.signIn(userId: userId)
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

            Section("API 配置") {
                if showApiKey {
                    TextField("请输入 OpenAI API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField("请输入 OpenAI API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Button(showApiKey ? "隐藏密钥" : "显示密钥") {
                    showApiKey.toggle()
                }

                if apiKey.isEmpty {
                    Text("未配置时将使用服务器默认 Key（如有）。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("已保存到本地，仅用于本机请求。")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
