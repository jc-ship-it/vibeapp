import SwiftUI
import AuthenticationServices

struct AccountView: View {
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var sync: SyncSettings
    @State private var signInError: String?
    @AppStorage("vibeapp_openai_key") private var apiKey: String = ""
    @State private var showApiKey = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("我的")
                        .font(.largeTitle.bold())
                    Text("管理账号、隐私与应用设置。")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.top, DesignTokens.Spacing.sm)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("账号")
                        .font(.title2.bold())
                    if auth.isSignedIn {
                        HStack {
                            Text("已登录")
                                .font(.headline)
                            Spacer()
                            Button("退出登录") {
                                auth.signOut()
                            }
                            .foregroundColor(.red)
                        }
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
                        .frame(height: DesignTokens.Sizes.minTap)
                    }

                    if let signInError {
                        Text(signInError)
                            .font(.callout)
                            .foregroundColor(.red)
                    }
                }
                .glassCard()

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("API 配置")
                        .font(.title2.bold())
                    if showApiKey {
                        TextField("请输入 OpenAI API Key", text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .frame(minHeight: DesignTokens.Sizes.minTap)
                    } else {
                        SecureField("请输入 OpenAI API Key", text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .frame(minHeight: DesignTokens.Sizes.minTap)
                    }

                    Button(showApiKey ? "隐藏密钥" : "显示密钥") {
                        showApiKey.toggle()
                    }
                    .font(.callout)

                    Text(apiKey.isEmpty ? "未填写时将使用服务器默认配置。" : "密钥已保存在本机。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("同步设置")
                        .font(.title2.bold())
                    Toggle("启用 iCloud 同步（文本与结构化数据）", isOn: $sync.useCloudSync)
                    Toggle("同步图片（可能包含敏感信息）", isOn: $sync.syncImages)
                        .disabled(!sync.useCloudSync)
                }
                .glassCard()
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
