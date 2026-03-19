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
    // 你的自定义网关（兼容 OpenAI Chat Completions）
    private let openAIChatCompletionsURL = URL(string: "https://z.apiyihe.org/v1/chat/completions")!
    private let openAIModel = "gpt-4.1"

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
            // 兜底：直连 OpenAI（如果用户在我的里填了 key）。
            if let key = currentApiKey {
                do {
                    return try await analyzeDirectOpenAI(texts: texts, apiKey: key)
                } catch {
                    // 继续兜底到本地规则，避免“Could not connect to the server”阻断流程。
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

    struct APIKeyValidationResult {
        let serverRunning: Bool
        let keyValid: Bool
        let message: String
    }

    func checkServerHealth(timeout: TimeInterval = 1.5) async -> Bool {
        let url = baseURL.appendingPathComponent("health")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout

        do {
            let (data, response) = try await URLSession(configuration: config).data(for: request)
            _ = data
            guard let http = response as? HTTPURLResponse else { return false }
            return http.statusCode == 200
        } catch {
            return false
        }
    }

    func validateCurrentAPIKey(timeout: TimeInterval = 6.0) async -> APIKeyValidationResult {
        let serverRunning = await checkServerHealth(timeout: timeout)

        guard let key = currentApiKey else {
            return APIKeyValidationResult(
                serverRunning: serverRunning,
                keyValid: false,
                message: "请先填写 OpenAI API Key"
            )
        }

        // 使用极小请求验证 Key 是否可用，避免解析响应内容。
        let ping = "ping"
        let requestBody = makeChatCompletionsAnalyzeRequest(inputText: ping, maxTokens: 1, temperature: 0.0)

        var request = URLRequest(url: openAIChatCompletionsURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONEncoder().encode(requestBody)

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout

        do {
            let (_, response) = try await URLSession(configuration: config).data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            switch status {
            case 200:
                return APIKeyValidationResult(serverRunning: serverRunning, keyValid: true, message: "API Key 可用")
            case 401:
                return APIKeyValidationResult(serverRunning: serverRunning, keyValid: false, message: "API Key 无效（401）")
            case 429:
                return APIKeyValidationResult(serverRunning: serverRunning, keyValid: true, message: "API Key 可用（可能已达配额，429）")
            default:
                return APIKeyValidationResult(serverRunning: serverRunning, keyValid: false, message: "API Key 异常（HTTP \(status)）")
            }
        } catch {
            return APIKeyValidationResult(serverRunning: serverRunning, keyValid: false, message: "无法连接到 OpenAI：\(error.localizedDescription)")
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
            "  \"summary\": \"整体摘要（2-3 句）\",",
            "  \"similarities\": [\"短主题标签1\", \"短主题标签2\"],",
            "  \"trends\": [\"趋势1（一句话）\", \"趋势2（一句话）\"]",
            "}",
            "约束：similarities 必须是短标签（每个不超过 6 个字符/字），不要长句；trends 每个最多 18 个字符。",
            "不要输出额外文本。",
            "",
            "输入文本：",
            texts.enumerated()
                .map { idx, t in "#\(idx + 1)\n\(t)" }
                .joined(separator: "\n\n"),
        ].joined(separator: "\n")

        let requestBody = makeChatCompletionsAnalyzeRequest(inputText: prompt, maxTokens: 400, temperature: 0.2)

        var request = URLRequest(url: openAIChatCompletionsURL)
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
        let prompt = """
        You are a personal knowledge assistant. Given OCR text extracted from a user's screenshot, write a concise 1-2 sentence summary in the same language as the text.

        Rules:
        1. Focus on WHAT the content is about and WHY someone might want to remember it.
        2. Never list keywords. Never use the phrase "包含...等关键词".
        3. Write naturally, as if reminding someone what they saved.
        4. For chat/conversation screenshots: summarize the discussion topic.
        5. For articles/posts: summarize the main argument or information.
        6. For UI/settings screens: describe what the user was configuring.
        7. Extract 3-5 meaningful tags (nouns or short noun phrases only).
        8. Exclude from tags: UI labels (收起, 展开, 返回, 确定, 取消, 设置, 更多, 分享, 复制, 删除), network indicators (4G, 5G, WiFi, LTE), single characters, pure numbers, words shorter than 2 Chinese characters or 3 English characters.

        Return JSON only:
        {"summary": "...", "tags": ["...", "..."], "keywords": ["...", "..."]}

        OCR text:
        \(text)
        """

        let requestBody = makeChatCompletionsAnalyzeRequest(inputText: prompt, maxTokens: 300, temperature: 0.2)

        var request = URLRequest(url: openAIChatCompletionsURL)
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

    // MARK: - OpenAI Chat Completions request/response helpers

    private func makeChatCompletionsAnalyzeRequest(inputText: String, maxTokens: Int, temperature: Double) -> ChatCompletionsAnalyzeRequest {
        ChatCompletionsAnalyzeRequest(
            model: openAIModel,
            messages: [
                ChatMessage(role: "user", content: inputText)
            ],
            maxTokens: maxTokens,
            temperature: temperature
        )
    }

    private struct ChatCompletionsAnalyzeRequest: Encodable {
        let model: String
        let messages: [ChatMessage]
        let maxTokens: Int
        let temperature: Double

        enum CodingKeys: String, CodingKey {
            case model
            case messages
            case maxTokens = "max_tokens"
            case temperature
        }
    }

    private struct ChatMessage: Encodable {
        let role: String
        let content: String
    }

    private func extractOutputText(from data: Data) throws -> String {
        // Chat Completions：
        // { "choices":[ { "message": { "content":"..." } } ] }
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let choices = obj?["choices"] as? [[String: Any]],
           let first = choices.first,
           let message = first["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }

        // 兜底：兼容旧 responses 结构（避免你还没完全切换时直接崩溃）
        if let outputText = obj?["output_text"] as? String {
            return outputText
        }

        throw NSError(
            domain: "AIService",
            code: 30,
            userInfo: [NSLocalizedDescriptionKey: "OpenAI 响应缺少 choices[0].message.content（或 output_text）"]
        )
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
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let summary: String
        if trimmed.isEmpty {
            summary = "内容较短，无法生成摘要。"
        } else {
            let preview = String(trimmed.prefix(50))
            summary = preview.count < trimmed.count ? "\(preview)…" : preview
        }
        let tokens = tokenize(text)
        let top = mostFrequent(tokens, limit: 5)
        let tags = top.prefix(3).map { $0 }
        return AICardAnalysisResponse(summary: summary, tags: tags, keywords: top)
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
