//
//  UpscaleJob.swift
//  VibeScaler
//

import Foundation

struct UpscaleJob: Identifiable, Codable {
    let id: String
    let inputURL: URL
    var outputURL: URL?
    let model: UpscaleModel
    let scale: ScaleFactor
    let quality: QualityPreset
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

// MARK: - Upscale Models

enum UpscaleModel: String, CaseIterable, Codable {
    case local = "local"
    case clarity = "fal-ai/clarity-upscaler"
    case creative = "fal-ai/creative-upscaler"
    case esrgan = "fal-ai/real-esrgan"

    var displayName: String {
        switch self {
        case .local: return "Standard (Local)"
        case .clarity: return "AI Clarity"
        case .creative: return "AI Creative"
        case .esrgan: return "AI Fast"
        }
    }

    var description: String {
        switch self {
        case .local: return "Fast local processing using ffmpeg. No AI, unlimited free use."
        case .clarity: return "Best for photos. Preserves detail while enhancing sharpness."
        case .creative: return "Adds AI-generated detail. Great for artwork and illustrations."
        case .esrgan: return "Fast AI upscaling. Good balance of speed and quality."
        }
    }

    var requiresCredits: Bool {
        self != .local
    }

    var estimatedCost: String {
        switch self {
        case .local: return "Free"
        case .clarity, .creative: return "1 credit"
        case .esrgan: return "1 credit"
        }
    }
}

// MARK: - Scale Factor

enum ScaleFactor: Int, CaseIterable, Codable {
    case x2 = 2
    case x4 = 4

    var displayName: String {
        "\(rawValue)×"
    }

    var description: String {
        switch self {
        case .x2: return "Double resolution"
        case .x4: return "Quadruple resolution"
        }
    }
}

// MARK: - Quality Preset

enum QualityPreset: String, CaseIterable, Codable {
    case fast = "fast"
    case balanced = "balanced"
    case quality = "quality"

    var displayName: String {
        switch self {
        case .fast: return "Fast"
        case .balanced: return "Balanced"
        case .quality: return "Maximum"
        }
    }

    var icon: String {
        switch self {
        case .fast: return "hare"
        case .balanced: return "scalemass"
        case .quality: return "star"
        }
    }
}
