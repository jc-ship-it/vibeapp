import Foundation

struct AIAnalysisResponse: Codable {
    let summary: String
    let similarities: [String]
    let trends: [String]
}

struct AICardAnalysisResponse: Codable {
    let summary: String
    let tags: [String]
    let keywords: [String]
}

final class AIService {
    static let shared = AIService()

    private init() {}

    // 开发期建议使用模拟器 + 本机服务，因此默认指向 localhost。
    // 真机调试时，如果需要访问同一局域网的 Mac，请将域名改为实际 IP 或主机名。
    private let baseURL = URL(string: "http://localhost:3000")!
    private let apiKeyKey = "vibeapp_openai_key"

    func analyze(texts: [String]) async throws -> AIAnalysisResponse {
        let url = baseURL.appendingPathComponent("analyze")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = UserDefaults.standard.string(forKey: apiKeyKey),
           !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "X-OpenAI-Key")
        }

        let body = ["texts": texts]
        request.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let message = String(data: data, encoding: .utf8) ?? "未知错误"
                print("AIService HTTP \(String(describing: (response as? HTTPURLResponse)?.statusCode)) body: \(message)")
                throw NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
            }
            return try JSONDecoder().decode(AIAnalysisResponse.self, from: data)
        } catch {
            print("AIService request failed: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("AIService URLError code: \(urlError.code.rawValue)")
            }
            throw error
        }
    }

    func analyzeCard(text: String) async throws -> AICardAnalysisResponse {
        let url = baseURL.appendingPathComponent("analyze-card")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = UserDefaults.standard.string(forKey: apiKeyKey),
           !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "X-OpenAI-Key")
        }

        struct Body: Codable { let text: String }
        request.httpBody = try JSONEncoder().encode(Body(text: text))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8) ?? "未知错误"
            throw NSError(domain: "AIService", code: 2, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return try JSONDecoder().decode(AICardAnalysisResponse.self, from: data)
    }
}
