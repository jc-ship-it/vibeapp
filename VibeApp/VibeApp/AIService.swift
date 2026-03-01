import Foundation

struct AIAnalysisResponse: Codable {
    let summary: String
    let similarities: [String]
    let trends: [String]
}

final class AIService {
    static let shared = AIService()

    private init() {}

    private let baseURL = URL(string: "http://192.168.31.62:3000")!

    func analyze(texts: [String]) async throws -> AIAnalysisResponse {
        let url = baseURL.appendingPathComponent("analyze")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["texts": texts]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8) ?? "未知错误"
            throw NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return try JSONDecoder().decode(AIAnalysisResponse.self, from: data)
    }
}
