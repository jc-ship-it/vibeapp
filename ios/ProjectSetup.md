iOS 工程创建步骤
==============

由于 Xcode 项目文件无法在此环境直接生成，请按以下方式创建：

1. 打开 Xcode，新建 iOS App（SwiftUI）。
2. 项目名填写 `VibeApp`。
3. 将 `ios/VibeApp` 目录下的所有 Swift 文件拖入 Xcode 工程。
4. 在 `Info.plist` 增加相册权限描述：
   - `NSPhotoLibraryUsageDescription`：用于选择截图并进行本地识别。

完成后即可运行并验证截图导入与 OCR 功能。
