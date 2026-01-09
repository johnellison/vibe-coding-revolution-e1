//
//  UpscaleViewModel.swift
//  VibeScaler
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import AppKit

class UpscaleViewModel: ObservableObject {
    // Input State
    @Published var selectedFile: URL?
    @Published var originalImage: NSImage?
    @Published var originalDimensions: CGSize?
    @Published var isDropTargeted: Bool = false

    // Options
    @Published var selectedModel: UpscaleModel = .local
    @Published var selectedScale: ScaleFactor = .x2
    @Published var selectedQuality: QualityPreset = .balanced

    // Processing State
    @Published var isProcessing: Bool = false
    @Published var progress: Double = 0
    @Published var statusMessage: String = ""

    // Result State
    @Published var processedImage: NSImage?
    @Published var processedURL: URL?
    @Published var hasResult: Bool = false

    // Services
    private let upscaleService = UpscaleService()

    // Supported Types
    let supportedTypes: [UTType] = [.jpeg, .png, .heic, .webP, .tiff, .image]

    // MARK: - Handle Drop

    func handleDrop(urls: [URL]) {
        guard let url = urls.first else { return }

        // Validate file type
        guard let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
              let utType = UTType(typeIdentifier) else {
            return
        }

        let isSupported = supportedTypes.contains { utType.conforms(to: $0) }
        guard isSupported else { return }

        // Load image
        guard let image = NSImage(contentsOf: url) else { return }

        selectedFile = url
        originalImage = image

        if let rep = image.representations.first {
            originalDimensions = CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
        }
    }

    // MARK: - Start Upscale

    func startUpscale() async {
        guard let inputURL = selectedFile else { return }

        await MainActor.run {
            isProcessing = true
            progress = 0
            statusMessage = "Preparing..."
        }

        do {
            let outputURL = try await upscaleService.upscale(
                url: inputURL,
                model: selectedModel,
                scale: selectedScale,
                quality: selectedQuality
            ) { [weak self] progressValue in
                Task { @MainActor in
                    self?.progress = progressValue
                    self?.statusMessage = self?.statusForProgress(progressValue) ?? ""
                }
            }

            await MainActor.run {
                self.processedURL = outputURL
                self.processedImage = NSImage(contentsOf: outputURL)
                self.hasResult = true
                self.isProcessing = false
            }

            // Reveal in Finder
            NSWorkspace.shared.activateFileViewerSelecting([outputURL])

        } catch {
            await MainActor.run {
                self.isProcessing = false
                // TODO: Show error
                print("Upscale failed: \(error)")
            }
        }
    }

    // MARK: - Cancel

    func cancel() {
        upscaleService.cancel()
        isProcessing = false
        progress = 0
    }

    // MARK: - Reset

    func reset() {
        selectedFile = nil
        originalImage = nil
        originalDimensions = nil
        processedImage = nil
        processedURL = nil
        hasResult = false
        progress = 0
        statusMessage = ""
    }

    // MARK: - Helpers

    private func statusForProgress(_ progress: Double) -> String {
        switch progress {
        case 0..<0.1:
            return "Preparing..."
        case 0.1..<0.3:
            return selectedModel == .local ? "Processing..." : "Uploading..."
        case 0.3..<0.9:
            return selectedModel == .local ? "Scaling image..." : "AI Enhancement in progress..."
        case 0.9..<1.0:
            return "Finalizing..."
        default:
            return "Complete!"
        }
    }
}
