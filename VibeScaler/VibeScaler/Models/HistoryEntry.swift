//
//  HistoryEntry.swift
//  VibeScaler
//

import Foundation
import AppKit

struct HistoryEntry: Identifiable, Codable {
    let id: UUID
    let originalFileName: String
    let originalURL: URL
    let processedURL: URL
    let originalWidth: Int
    let originalHeight: Int
    let processedWidth: Int
    let processedHeight: Int
    let model: UpscaleModel
    let scale: ScaleFactor
    let quality: QualityPreset
    let processingTime: TimeInterval
    let timestamp: Date
    let fileType: FileType

    enum FileType: String, Codable {
        case image
        case video
    }

    var originalSize: String {
        "\(originalWidth) × \(originalHeight)"
    }

    var processedSize: String {
        "\(processedWidth) × \(processedHeight)"
    }

    var modelName: String {
        model.displayName
    }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var thumbnail: NSImage? {
        guard fileType == .image else { return nil }
        return NSImage(contentsOf: processedURL)
    }
}

// MARK: - History Manager

class HistoryManager: ObservableObject {
    @Published var entries: [HistoryEntry] = []

    private let historyKey = "com.johnellison.vibescaler.history"
    private let maxEntries = 100

    init() {
        loadHistory()
    }

    func addEntry(_ entry: HistoryEntry) {
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        saveHistory()
    }

    func removeEntry(_ entry: HistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        saveHistory()
    }

    func clearHistory() {
        entries.removeAll()
        saveHistory()
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) else {
            return
        }
        entries = decoded
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }
}
