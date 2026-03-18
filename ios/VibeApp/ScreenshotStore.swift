import Foundation
import UIKit

final class ScreenshotStore: ObservableObject {
    @Published private(set) var items: [ScreenshotItem] = []
    @Published private(set) var reports: [TrendReport] = []
    @Published var latestReport: TrendReport?

    private let fileManager = FileManager.default
    private let itemsURL: URL
    private let reportsURL: URL
    private let imagesFolderURL: URL

    init() {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        itemsURL = documents.appendingPathComponent("screenshot_items.json")
        reportsURL = documents.appendingPathComponent("trend_reports.json")
        imagesFolderURL = documents.appendingPathComponent("screenshots", isDirectory: true)
        loadItems()
        loadReports()
    }

    func addScreenshot(imageData: Data, ocrText: String, confidence: Double?) {
        let imagePath = saveImage(data: imageData)
        let item = ScreenshotItem(ocrText: ocrText, ocrConfidence: confidence, imageLocalPath: imagePath?.path)
        items.insert(item, at: 0)
        saveItems()
    }

    func update(item: ScreenshotItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        saveItems()
    }

    func deleteItems(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        items.removeAll { ids.contains($0.id) }
        saveItems()
    }

    func deleteAllItems() {
        items.removeAll()
        saveItems()
    }

    func setReport(_ report: TrendReport) {
        latestReport = report
        reports.insert(report, at: 0)
        saveReports()
    }

    private func loadItems() {
        guard let data = try? Data(contentsOf: itemsURL) else { return }
        if let decoded = try? JSONDecoder().decode([ScreenshotItem].self, from: data) {
            items = decoded
        }
    }

    private func saveItems() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: itemsURL, options: [.atomic])
    }

    private func loadReports() {
        guard let data = try? Data(contentsOf: reportsURL) else { return }
        if let decoded = try? JSONDecoder().decode([TrendReport].self, from: data) {
            reports = decoded
            latestReport = decoded.first
        }
    }

    private func saveReports() {
        guard let data = try? JSONEncoder().encode(reports) else { return }
        try? data.write(to: reportsURL, options: [.atomic])
    }

    private func saveImage(data: Data) -> URL? {
        if !fileManager.fileExists(atPath: imagesFolderURL.path) {
            try? fileManager.createDirectory(at: imagesFolderURL, withIntermediateDirectories: true)
        }
        let filename = UUID().uuidString + ".jpg"
        let url = imagesFolderURL.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            return nil
        }
    }
}
