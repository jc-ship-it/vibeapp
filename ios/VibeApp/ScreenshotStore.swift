import Foundation
import UIKit

final class ScreenshotStore: ObservableObject {
    @Published private(set) var items: [ScreenshotItem] = []
    @Published var latestReport: TrendReport?

    private let fileManager = FileManager.default
    private let itemsURL: URL
    private let imagesFolderURL: URL

    init() {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        itemsURL = documents.appendingPathComponent("screenshot_items.json")
        imagesFolderURL = documents.appendingPathComponent("screenshots", isDirectory: true)
        loadItems()
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

    func setReport(_ report: TrendReport) {
        latestReport = report
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
