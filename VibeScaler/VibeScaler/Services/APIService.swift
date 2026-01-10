//
//  APIService.swift
//  VibeScaler
//

import Foundation

class APIService {
    // TODO: Replace with actual backend URL
    private let baseURL = "https://vibescaler-api.workers.dev"

    private var sessionToken: String? {
        UserDefaults.standard.string(forKey: "sessionToken")
    }

    // MARK: - Upscale Image

    func upscaleImage(
        inputURL: URL,
        model: UpscaleModel,
        scale: ScaleFactor,
        progress: @escaping (Double) -> Void
    ) async throws -> URL {
        guard let token = sessionToken else {
            throw APIError.unauthorized
        }

        // Step 1: Upload image and start job
        let jobId = try await startUpscaleJob(inputURL: inputURL, model: model, scale: scale, token: token)

        progress(0.3)

        // Step 2: Poll for completion
        let resultURL = try await pollJobStatus(jobId: jobId, token: token, progress: progress)

        return resultURL
    }

    // MARK: - Start Job

    private func startUpscaleJob(
        inputURL: URL,
        model: UpscaleModel,
        scale: ScaleFactor,
        token: String
    ) async throws -> String {
        // Read image data
        let imageData = try Data(contentsOf: inputURL)
        let base64Image = imageData.base64EncodedString()

        // Build request
        let url = URL(string: "\(baseURL)/api/upscale/image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "image": "data:image/\(inputURL.pathExtension);base64,\(base64Image)",
            "model": model.rawValue,
            "scale": scale.rawValue
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            let result = try JSONDecoder().decode(UpscaleJobResponse.self, from: data)
            return result.jobId
        case 401:
            throw APIError.unauthorized
        case 402:
            throw APIError.insufficientCredits
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    // MARK: - Poll Status

    private func pollJobStatus(
        jobId: String,
        token: String,
        progress: @escaping (Double) -> Void
    ) async throws -> URL {
        let url = URL(string: "\(baseURL)/api/upscale/status/\(jobId)")!

        var attempts = 0
        let maxAttempts = 60 // 60 seconds max

        while attempts < maxAttempts {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: request)
            let status = try JSONDecoder().decode(JobStatusResponse.self, from: data)

            switch status.status {
            case "completed":
                guard let resultURL = status.resultUrl else {
                    throw APIError.noResult
                }
                return URL(string: resultURL)!

            case "failed":
                throw APIError.processingFailed(status.error ?? "Unknown error")

            case "processing":
                progress(min(0.9, 0.3 + Double(attempts) * 0.01))

            default:
                break
            }

            attempts += 1
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }

        throw APIError.timeout
    }

    // MARK: - Remove Background

    func removeBackground(
        inputURL: URL,
        model: BackgroundRemovalModel,
        progress: @escaping (Double) -> Void
    ) async throws -> URL {
        guard let token = sessionToken else {
            throw APIError.unauthorized
        }

        // Read image data
        let imageData = try Data(contentsOf: inputURL)
        let base64Image = imageData.base64EncodedString()

        // Build request
        let url = URL(string: "\(baseURL)/api/remove-background")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "image": "data:image/\(inputURL.pathExtension);base64,\(base64Image)",
            "model": model.rawValue
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        progress(0.3)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            let result = try JSONDecoder().decode(RemoveBackgroundResponse.self, from: data)
            guard let resultURL = result.resultUrl else {
                throw APIError.noResult
            }
            progress(0.9)
            return URL(string: resultURL)!
        case 401:
            throw APIError.unauthorized
        case 402:
            throw APIError.insufficientCredits
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    // MARK: - Get Credits

    func getCredits() async throws -> (imageCredits: Int, videoSeconds: Int) {
        guard let token = sessionToken else {
            throw APIError.unauthorized
        }

        let url = URL(string: "\(baseURL)/api/user/credits")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        let credits = try JSONDecoder().decode(CreditsResponse.self, from: data)
        return (credits.imageCredits, credits.videoSeconds)
    }
}

// MARK: - Response Types

struct UpscaleJobResponse: Codable {
    let jobId: String
    let status: String
}

struct JobStatusResponse: Codable {
    let status: String
    let resultUrl: String?
    let error: String?
}

struct CreditsResponse: Codable {
    let imageCredits: Int
    let videoSeconds: Int
}

struct RemoveBackgroundResponse: Codable {
    let status: String
    let resultUrl: String?
    let error: String?
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case unauthorized
    case insufficientCredits
    case rateLimited
    case invalidResponse
    case serverError(Int)
    case processingFailed(String)
    case timeout
    case noResult

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please sign in to use AI upscaling."
        case .insufficientCredits:
            return "Not enough credits. Purchase more in the Store."
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        case .invalidResponse:
            return "Invalid server response."
        case .serverError(let code):
            return "Server error (\(code)). Please try again."
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        case .timeout:
            return "Request timed out. Please try again."
        case .noResult:
            return "No result received from server."
        }
    }
}
