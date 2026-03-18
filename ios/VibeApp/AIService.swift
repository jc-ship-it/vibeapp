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

    // 优先走本机服务（适合模拟器 + Mac 开后端）。
    // 若设备端无法访问该地址，则会自动回退到 OpenAI 直连，保证“立刻可用”。
    private let baseURL = URL(string: "http://localhost:3000")!
    private let apiKeyKey = "vibeapp_openai_key"
    private let openAIResponsesURL = URL(string: "https://api.openai.com/v1/responses")!
    private let openAIModel = "gpt-4.1-mini"

    private var currentApiKey: String? {
        guard let key = UserDefaults.standard.string(forKey: apiKeyKey),
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return key
    }

    func analyze(texts: [String]) async throws -> AIAnalysisResponse {
        do {
            return try await analyzeViaServer(texts: texts)
        } catch {
            if let key = currentApiKey {
                do {
                    return try await analyzeDirectOpenAI(texts: texts, apiKey: key)
                } catch {
                    // 继续兜底到本地规则
                }
            }
            return fallbackAnalyzeLocal(texts: texts)
        }
    }

    func analyzeCard(text: String) async throws -> AICardAnalysisResponse {
        do {
            return try await analyzeCardViaServer(text: text)
        } catch {
            if let key = currentApiKey {
                do {
                    return try await analyzeCardDirectOpenAI(text: text, apiKey: key)
                } catch {
                    // 继续兜底到本地规则
                }
            }
            return fallbackAnalyzeCardLocal(text: text)
        }
    }

    private func analyzeViaServer(texts: [String]) async throws -> AIAnalysisResponse {
        let url = baseURL.appendingPathComponent("analyze")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = currentApiKey {
            request.setValue(apiKey, forHTTPHeaderField: "X-OpenAI-Key")
        }

        let body = ["texts": texts]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8) ?? "未知错误"
            throw NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return try JSONDecoder().decode(AIAnalysisResponse.self, from: data)
    }

    private func analyzeCardViaServer(text: String) async throws -> AICardAnalysisResponse {
        let url = baseURL.appendingPathComponent("analyze-card")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = currentApiKey {
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

    private func analyzeDirectOpenAI(texts: [String], apiKey: String) async throws -> AIAnalysisResponse {
        let prompt = [
            "你是信息整理助手。请根据一段时间内的多条截图 OCR 文本，生成复盘用的趋势报告。",
            "只返回 JSON，格式如下：",
            "{",
            '  "summary": "整体摘要（2-3 句）",',
            '  "similarities": ["用作标签的高频主题1", "高频主题2"],',
            '  "trends": ["趋势1（一句话）", "趋势2（一句话）"]',
            "}",
            "不要输出额外文本。",
            "",
            "输入文本：",
            texts.enumerated()
                .map { idx, t in "#\(idx + 1)\n\(t)" }
                .joined(separator: "\n\n"),
        ].joined(separator: "\n")

        let requestBody = makeResponsesAnalyzeRequest(inputText: prompt, maxTokens: 400, temperature: 0.2)

        var request = URLRequest(url: openAIResponsesURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8) ?? "未知错误"
            throw NSError(domain: "AIService", code: 10, userInfo: [NSLocalizedDescriptionKey: message])
        }

        let outputText = try extractOutputText(from: data)
        guard let parsed: AIAnalysisResponse = decodeJSONFromModelOutput(outputText) else {
            throw NSError(domain: "AIService", code: 11, userInfo: [NSLocalizedDescriptionKey: "OpenAI 返回无法解析为 JSON"])
        }
        return parsed
    }

    private func analyzeCardDirectOpenAI(text: String, apiKey: String) async throws -> AICardAnalysisResponse {
        let prompt = [
            "你是信息整理助手，负责为单条截图生成摘要和标签。",
            "只返回 JSON，格式如下：",
            "{",
            '  "summary": "一句话摘要",',
            '  "tags": ["标签1", "标签2"],',
            '  "keywords": ["关键词1", "关键词2", "关键词3"]',
            "}",
            "不要输出额外文本。",
            "",
            "截图 OCR 文本：",
            text
        ].joined(separator: "\n")

        let requestBody = makeResponsesAnalyzeRequest(inputText: prompt, maxTokens: 300, temperature: 0.2)

        var request = URLRequest(url: openAIResponsesURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8) ?? "未知错误"
            throw NSError(domain: "AIService", code: 20, userInfo: [NSLocalizedDescriptionKey: message])
        }

        let outputText = try extractOutputText(from: data)
        guard let parsed: AICardAnalysisResponse = decodeJSONFromModelOutput(outputText) else {
            throw NSError(domain: "AIService", code: 21, userInfo: [NSLocalizedDescriptionKey: "OpenAI 返回无法解析为 JSON"])
        }
        return parsed
    }

    // MARK: - OpenAI responses request/response helpers

    private func makeResponsesAnalyzeRequest(
        inputText: String,
        maxTokens: Int,
        temperature: Double
    ) -> ResponsesAnalyzeRequest {
        ResponsesAnalyzeRequest(
            model: openAIModel,
            input: [
                ResponsesInput(
                    role: "user",
                    content: [
                        ResponsesContent(type: "input_text", text: inputText)
                    ]
                )
            ],
            maxOutputTokens: maxTokens,
            temperature: temperature
        )
    }

    private struct ResponsesAnalyzeRequest: Encodable {
        let model: String
        let input: [ResponsesInput]
        let maxOutputTokens: Int
        let temperature: Double

        enum CodingKeys: String, CodingKey {
            case model
            case input
            case maxOutputTokens = "max_output_tokens"
            case temperature
        }
    }

    private struct ResponsesInput: Encodable {
        let role: String
        let content: [ResponsesContent]
    }

    private struct ResponsesContent: Encodable {
        let type: String
        let text: String
    }

    private func extractOutputText(from data: Data) throws -> String {
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let outputText = obj?["output_text"] as? String {
            return outputText
        }

        if let output = obj?["output"] as? [[String: Any]] {
            if let first = output.first,
               let content = first["content"] as? [[String: Any]],
               let text = content.first?["text"] as? String {
                return text
            }
        }

        throw NSError(domain: "AIService", code: 30, userInfo: [NSLocalizedDescriptionKey: "OpenAI 响应缺少 output_text"])
    }

    private func decodeJSONFromModelOutput<T: Decodable>(_ outputText: String) -> T? {
        guard let start = outputText.firstIndex(of: "{"),
              let end = outputText.lastIndex(of: "}") else { return nil }
        let jsonString = String(outputText[start...end])
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: jsonData)
    }

    // MARK: - Local fallback

    private func fallbackAnalyzeLocal(texts: [String]) -> AIAnalysisResponse {
        let joined = texts.joined(separator: "\n")
        let tokens = tokenize(joined)
        let top = mostFrequent(tokens, limit: 5)

        let summary = top.isEmpty ? "本地摘要：内容较短。" : "本地摘要：包含 \(top.joined(separator: "、")) 等关键词。"
        let similarities = top
        let trends = top.prefix(2).map { "围绕 \($0) 的共性可能在增多。" }
        return AIAnalysisResponse(summary: summary, similarities: similarities, trends: trends)
    }

    private func fallbackAnalyzeCardLocal(text: String) -> AICardAnalysisResponse {
        let tokens = tokenize(text)
        let top = mostFrequent(tokens, limit: 5)
        let summary = top.isEmpty ? "本地摘要：内容较短。" : "本地摘要：包含 \(top.joined(separator: "、")) 等关键词。"
        return AICardAnalysisResponse(summary: summary, tags: Array(top.prefix(3)), keywords: top)
    }

    private func tokenize(_ input: String) -> [String] {
        let pattern = "[^\\p{Han}A-Za-z0-9\\s]"
        let cleaned = input.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
        return cleaned
            .split { $0.isWhitespace || $0.isNewline }
            .map(String.init)
            .filter { $0.count > 1 }
    }

    private func mostFrequent(_ tokens: [String], limit: Int) -> [String] {
        guard !tokens.isEmpty else { return [] }
        var counts: [String: Int] = [:]
        for t in tokens {
            counts[t, default: 0] += 1
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }
}
