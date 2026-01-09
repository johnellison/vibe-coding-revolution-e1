//
//  LocalUpscaler.swift
//  VibeScaler
//

import Foundation
import AppKit

class LocalUpscaler {
    private let ffmpegPath: String?

    init() {
        // Try to find ffmpeg
        ffmpegPath = LocalUpscaler.findFFmpeg()
    }

    var isAvailable: Bool {
        ffmpegPath != nil
    }

    // MARK: - Find FFmpeg

    private static func findFFmpeg() -> String? {
        // Check common locations
        let paths = [
            "/opt/homebrew/bin/ffmpeg",     // Apple Silicon Homebrew
            "/usr/local/bin/ffmpeg",         // Intel Homebrew
            "/usr/bin/ffmpeg",               // System
            Bundle.main.bundlePath + "/Contents/Resources/ffmpeg" // Bundled
        ]

        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        // Try which command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ffmpeg"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty {
                return output
            }
        } catch {
            print("Could not find ffmpeg: \(error)")
        }

        return nil
    }

    // MARK: - Upscale

    func upscale(
        inputURL: URL,
        scale: ScaleFactor,
        quality: QualityPreset,
        progress: @escaping (Double) -> Void
    ) async throws -> URL {
        guard let ffmpeg = ffmpegPath else {
            throw LocalUpscalerError.ffmpegNotFound
        }

        // Get original dimensions
        let dimensions = try getImageDimensions(inputURL)
        let newWidth = dimensions.width * scale.rawValue
        let newHeight = dimensions.height * scale.rawValue

        // Generate output path
        let baseName = (inputURL.lastPathComponent as NSString).deletingPathExtension
        let ext = inputURL.pathExtension.lowercased()
        let outputName = "\(baseName)_\(scale.rawValue)x.\(ext)"

        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let outputURL = downloadsURL.appendingPathComponent(outputName)

        // Remove existing file
        try? FileManager.default.removeItem(at: outputURL)

        // Build ffmpeg arguments
        var args = [
            "-i", inputURL.path,
            "-vf", "scale=\(newWidth):\(newHeight):flags=\(scaleFlag(for: quality))"
        ]

        // Quality settings based on format
        switch ext {
        case "jpg", "jpeg":
            args += ["-q:v", qualityValue(for: quality, format: .jpeg)]
        case "png":
            args += ["-compression_level", "6"]
        case "webp":
            args += ["-quality", qualityValue(for: quality, format: .webp)]
        default:
            break
        }

        args += ["-y", outputURL.path]

        // Run ffmpeg
        progress(0.1)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpeg)
        process.arguments = args

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()

        // Simulate progress (ffmpeg doesn't provide progress for images)
        for i in 1...8 {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            progress(0.1 + Double(i) * 0.1)
        }

        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw LocalUpscalerError.processingFailed(errorMessage)
        }

        progress(1.0)
        return outputURL
    }

    // MARK: - Helpers

    private func getImageDimensions(_ url: URL) throws -> (width: Int, height: Int) {
        guard let image = NSImage(contentsOf: url),
              let rep = image.representations.first else {
            throw LocalUpscalerError.invalidInput
        }
        return (rep.pixelsWide, rep.pixelsHigh)
    }

    private func scaleFlag(for quality: QualityPreset) -> String {
        switch quality {
        case .fast: return "bilinear"
        case .balanced: return "bicubic"
        case .quality: return "lanczos"
        }
    }

    private enum OutputFormat {
        case jpeg, webp, png
    }

    private func qualityValue(for quality: QualityPreset, format: OutputFormat) -> String {
        switch format {
        case .jpeg:
            switch quality {
            case .fast: return "8"
            case .balanced: return "4"
            case .quality: return "2"
            }
        case .webp:
            switch quality {
            case .fast: return "75"
            case .balanced: return "85"
            case .quality: return "95"
            }
        case .png:
            return "6" // compression level
        }
    }
}

// MARK: - Errors

enum LocalUpscalerError: LocalizedError {
    case ffmpegNotFound
    case invalidInput
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .ffmpegNotFound:
            return "FFmpeg not found. Please install FFmpeg using Homebrew: brew install ffmpeg"
        case .invalidInput:
            return "Could not read the input file."
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        }
    }
}
