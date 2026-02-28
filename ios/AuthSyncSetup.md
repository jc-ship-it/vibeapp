账号与同步配置
===========

Apple 登录
---------
1. 在 Xcode 中开启 `Sign In with Apple` 能力。
2. 确保 `Associated Domains` 与 `Keychain Sharing` 按需配置。
3. 真机运行时检查授权流程。

iCloud 同步
----------
1. 在 Xcode 中开启 `iCloud` 能力，勾选 `CloudKit`。
2. 配置容器（Container）并同步到 Apple Developer 账号。
3. 后续将本地数据从 JSON/本地文件切换到 CloudKit 或 Core Data + CloudKit。
