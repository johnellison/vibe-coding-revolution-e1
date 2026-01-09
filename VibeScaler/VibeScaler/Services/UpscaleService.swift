//
//  UpscaleService.swift
//  VibeScaler
//

import Foundation
import AppKit

class UpscaleService: ObservableObject {
    @Published var currentJob: UpscaleJob?
    @Published var isProcessing: Bool = false

    private let localUpscaler = LocalUpscaler()
    private let apiService = APIService()

    // MARK: - Main Upscale Function

    func upscale(
        url: URL,
        model: UpscaleModel,
        scale: ScaleFactor,
        quality: QualityPreset,
        progress: @escaping (Double) -> Void
    ) async throws -> URL {
        let job = UpscaleJob(
            id: UUID().uuidString,
            inputURL: url,
            model: model,
            scale: scale,
            quality: quality,
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

        if model == .local {
            return try await upscaleLocally(job: job, progress: progress)
        } else {
            return try await upscaleWithAI(job: job, progress: progress)
        }
    }

    // MARK: - Local Upscaling (ffmpeg)

    private func upscaleLocally(job: UpscaleJob, progress: @escaping (Double) -> Void) async throws -> URL {
        await MainActor.run {
            currentJob?.status = .processing
        }

        let outputURL = try await localUpscaler.upscale(
            inputURL: job.inputURL,
            scale: job.scale,
            quality: job.quality,
            progress: progress
        )

        await MainActor.run {
            currentJob?.status = .completed
            currentJob?.outputURL = outputURL
            currentJob?.completedAt = Date()
        }

        return outputURL
    }

    // MARK: - AI Upscaling (fal.ai via proxy)

    private func upscaleWithAI(job: UpscaleJob, progress: @escaping (Double) -> Void) async throws -> URL {
        // Upload phase (0-30%)
        await MainActor.run {
            currentJob?.status = .uploading
        }

        progress(0.1)

        let resultURL = try await apiService.upscaleImage(
            inputURL: job.inputURL,
            model: job.model,
            scale: job.scale
        ) { serverProgress in
            // Map server progress (0-1) to (0.3-0.9)
            progress(0.3 + (serverProgress * 0.6))
        }

        // Download phase (90-100%)
        await MainActor.run {
            currentJob?.status = .downloading
        }

        let localURL = try await downloadResult(from: resultURL, originalName: job.inputURL.lastPathComponent)

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

        // Generate output filename
        let baseName = (originalName as NSString).deletingPathExtension
        let outputName = "\(baseName)_upscaled.png"

        // Save to Downloads folder
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let outputURL = downloadsURL.appendingPathComponent(outputName)

        try data.write(to: outputURL)

        return outputURL
    }

    // MARK: - Cancel

    func cancel() {
        // TODO: Implement cancellation
        Task { @MainActor in
            currentJob?.status = .cancelled
            isProcessing = false
        }
    }
}
