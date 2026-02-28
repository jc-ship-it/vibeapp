import Foundation
import Vision
import UIKit

struct OCRResult {
    let text: String
    let confidence: Double?
}

final class OCRService {
    static let shared = OCRService()

    private init() {}

    func recognizeText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "OCRService", code: 1, userInfo: [NSLocalizedDescriptionKey: "图片格式不支持"])
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                let confidences = observations.compactMap { $0.topCandidates(1).first?.confidence }

                let text = lines.joined(separator: "\n")
                let averageConfidence: Double? = confidences.isEmpty
                    ? nil
                    : Double(confidences.reduce(0, +)) / Double(confidences.count)

                continuation.resume(returning: OCRResult(text: text, confidence: averageConfidence))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
