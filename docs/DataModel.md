本地数据结构
==========

说明
----
数据以本地优先的方式存储，图片文件可选择不上传。云端仅同步 OCR 文本与结构化字段。

实体设计（草案）
--------------
1. ScreenshotItem
   - id: UUID
   - createdAt: Date
   - source: String (相册/导入)
   - sourceApp: String? (小红书/B 站等)
   - sourceContext: String? (帖子/评论/收藏等)
   - imageLocalPath: String? (仅本地)
   - ocrText: String
   - ocrLanguage: String?
   - ocrConfidence: Double?

2. InsightCard
   - id: UUID
   - createdAt: Date
   - screenshotIds: [UUID]
   - summary: String?
   - tags: [String]
   - keywords: [String]

3. TrendReport
   - id: UUID
   - createdAt: Date
   - periodStart: Date
   - periodEnd: Date
   - summary: String
   - highlights: [String]
