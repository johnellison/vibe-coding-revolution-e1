//
//  BackgroundRemovalService.swift
//  VibeScaler
//
//  Background removal using fal.ai BiRefNet and Bria models
//

import Foundation
import AppKit

// MARK: - Background Removal Models

enum BackgroundRemovalModel: String, CaseIterable, Codable {
    case portrait = "portrait"
    case general = "general"
    case heavy = "heavy"
    case bria = "bria"

    var displayName: String {
        switch self {
        case .portrait: return "Portrait"
        case .general: return "General"
        case .heavy: return "High Quality"
        case .bria: return "Commercial Safe"
        }
    }

    var description: String {
        switch self {
        case .portrait: return "Optimized for people and portraits"
        case .general: return "Fast general-purpose removal"
        case .heavy: return "Slower but more accurate"
        case .bria: return "Trained on licensed data, safe for commercial use"
        }
    }

    var icon: String {
        switch self {
        case .portrait: return "person.crop.circle"
        case .general: return "hare"
        case .heavy: return "star.circle"
        case .bria: return "checkmark.seal"
        }
    }

    var apiModel: String {
        switch self {
        case .portrait, .general, .heavy:
            return "fal-ai/birefnet"
        case .bria:
            return "fal-ai/bria/background/remove"
        }
    }

    var modelType: String? {
        switch self {
        case .portrait: return "Portrait"
        case .general: return "General Use (Light)"
        case .heavy: return "General Use (Heavy)"
        case .bria: return nil
        }
    }

    var estimatedCost: String {
        switch self {
        case .portrait, .general, .bria: return "~$0.01"
        case .heavy: return "~$0.02"
        }
    }
}

// MARK: - Background Removal Job

struct BackgroundRemovalJob: Identifiable, Codable {
    let id: String
    let inputURL: URL
    var outputURL: URL?
    let model: BackgroundRemovalModel
    var status: JobStatus
    var progress: Double
    var error: String?
    let createdAt: Date
    var completedAt: Date?

    enum JobStatus: String, Codable {
        case pending
        case uploading
        case processing
        case downloading
        case completed
        case failed
        case cancelled
    }
}

// MARK: - Background Removal Service

class BackgroundRemovalService: ObservableObject {
    @Published var currentJob: BackgroundRemovalJob?
    @Published var isProcessing: Bool = false

    private let apiService = APIService()

    // MARK: - Remove Background

    func removeBackground(
        url: URL,
        model: BackgroundRemovalModel,
        progress: @escaping (Double) -> Void
    ) async throws -> URL {
        let job = BackgroundRemovalJob(
            id: UUID().uuidString,
            inputURL: url,
            model: model,
            status: .pending,
            progress: 0,
            createdAt: Date()
        )

        await MainActor.run {
            self.currentJob = job
            self.isProcessing = true
        }

        defer {
            Task { @MainActor in
                self.isProcessing = false
            }
        }

        // Upload phase (0-30%)
        await MainActor.run {
            currentJob?.status = .uploading
        }
        progress(0.1)

        // Process via API
        let resultURL = try await apiService.removeBackground(
            inputURL: url,
            model: model
        ) { serverProgress in
            progress(0.3 + (serverProgress * 0.6))
        }

        // Download phase (90-100%)
        await MainActor.run {
            currentJob?.status = .downloading
        }

        let localURL = try await downloadResult(
            from: resultURL,
            originalName: url.lastPathComponent
        )

        progress(1.0)

        await MainActor.run {
            currentJob?.status = .completed
            currentJob?.outputURL = localURL
            currentJob?.completedAt = Date()
        }

        return localURL
    }

    // MARK: - Download Result

    private func downloadResult(from url: URL, originalName: String) async throws -> URL {
        let (data, _) = try await URLSession.shared.data(from: url)

        // Generate output filename (always PNG for transparency)
        let baseName = (originalName as NSString).deletingPathExtension
        let outputName = "\(baseName)_no_bg.png"

        // Save to Downloads folder
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let outputURL = downloadsURL.appendingPathComponent(outputName)

        try data.write(to: outputURL)

        return outputURL
    }

    // MARK: - Cancel

    func cancel() {
        Task { @MainActor in
            currentJob?.status = .cancelled
            isProcessing = false
        }
    }
}
