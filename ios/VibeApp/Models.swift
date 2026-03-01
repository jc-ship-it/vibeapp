import Foundation

struct ScreenshotItem: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    var ocrText: String
    var ocrConfidence: Double?
    var imageLocalPath: String?
    var sourceApp: String?
    var sourceContext: String?
    var tags: [String]
    var summary: String?
    var keywords: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case ocrText
        case ocrConfidence
        case imageLocalPath
        case sourceApp
        case sourceContext
        case tags
        case summary
        case keywords
    }

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        ocrText: String,
        ocrConfidence: Double? = nil,
        imageLocalPath: String? = nil,
        sourceApp: String? = nil,
        sourceContext: String? = nil,
        tags: [String] = [],
        summary: String? = nil,
        keywords: [String] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.ocrText = ocrText
        self.ocrConfidence = ocrConfidence
        self.imageLocalPath = imageLocalPath
        self.sourceApp = sourceApp
        self.sourceContext = sourceContext
        self.tags = tags
        self.summary = summary
        self.keywords = keywords
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        ocrText = try container.decode(String.self, forKey: .ocrText)
        ocrConfidence = try container.decodeIfPresent(Double.self, forKey: .ocrConfidence)
        imageLocalPath = try container.decodeIfPresent(String.self, forKey: .imageLocalPath)
        sourceApp = try container.decodeIfPresent(String.self, forKey: .sourceApp)
        sourceContext = try container.decodeIfPresent(String.self, forKey: .sourceContext)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        keywords = try container.decodeIfPresent([String].self, forKey: .keywords) ?? []
    }
}

struct TrendReport: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    let periodStart: Date
    let periodEnd: Date
    let summary: String
    let similarities: [String]
    let trends: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case periodStart
        case periodEnd
        case summary
        case similarities
        case trends
        case highlights
    }

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        periodStart: Date,
        periodEnd: Date,
        summary: String,
        similarities: [String],
        trends: [String]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.summary = summary
        self.similarities = similarities
        self.trends = trends
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        periodStart = try container.decode(Date.self, forKey: .periodStart)
        periodEnd = try container.decode(Date.self, forKey: .periodEnd)
        summary = try container.decode(String.self, forKey: .summary)
        let decodedSimilarities = try container.decodeIfPresent([String].self, forKey: .similarities) ?? []
        let decodedTrends = try container.decodeIfPresent([String].self, forKey: .trends) ?? []
        if decodedSimilarities.isEmpty && decodedTrends.isEmpty {
            let highlights = try container.decodeIfPresent([String].self, forKey: .highlights) ?? []
            similarities = highlights
            trends = []
        } else {
            similarities = decodedSimilarities
            trends = decodedTrends
        }
    }
}
