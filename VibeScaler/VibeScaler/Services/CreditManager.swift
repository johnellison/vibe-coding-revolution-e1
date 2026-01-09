//
//  CreditManager.swift
//  VibeScaler
//

import Foundation
import StoreKit

class CreditManager: ObservableObject {
    @Published var imageCredits: Int = 0
    @Published var videoSeconds: Int = 0
    @Published var isLoading: Bool = false
    @Published var products: [Product] = []

    var videoMinutes: Double {
        Double(videoSeconds) / 60.0
    }

    var hasImageCredits: Bool {
        imageCredits > 0
    }

    var hasVideoCredits: Bool {
        videoSeconds > 0
    }

    // MARK: - Product IDs

    enum ProductID: String, CaseIterable {
        case images10 = "com.johnellison.vibescaler.credits.10"
        case images50 = "com.johnellison.vibescaler.credits.50"
        case images100 = "com.johnellison.vibescaler.credits.100"
        case video2min = "com.johnellison.vibescaler.video.2min"
        case video5min = "com.johnellison.vibescaler.video.5min"
        case video15min = "com.johnellison.vibescaler.video.15min"
        case proMonthly = "com.johnellison.vibescaler.pro.monthly"
    }

    init() {
        Task {
            await loadProducts()
            await refreshCredits()
        }
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let productIds = ProductID.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIds)

            await MainActor.run {
                self.products = storeProducts.sorted { $0.price < $1.price }
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                // Process the purchase
                await processTransaction(transaction)
                await transaction.finish()
            case .unverified:
                throw PurchaseError.verificationFailed
            }
        case .userCancelled:
            throw PurchaseError.cancelled
        case .pending:
            throw PurchaseError.pending
        @unknown default:
            throw PurchaseError.unknown
        }
    }

    private func processTransaction(_ transaction: Transaction) async {
        // TODO: Send receipt to backend for verification
        // For now, add credits locally

        guard let productId = ProductID(rawValue: transaction.productID) else { return }

        await MainActor.run {
            switch productId {
            case .images10:
                self.imageCredits += 10
            case .images50:
                self.imageCredits += 50
            case .images100:
                self.imageCredits += 100
            case .video2min:
                self.videoSeconds += 120
            case .video5min:
                self.videoSeconds += 300
            case .video15min:
                self.videoSeconds += 900
            case .proMonthly:
                self.imageCredits += 75
                self.videoSeconds += 300
            }
        }

        saveCreditsLocally()
    }

    // MARK: - Credit Operations

    func deductImageCredit() -> Bool {
        guard imageCredits > 0 else { return false }
        imageCredits -= 1
        saveCreditsLocally()
        return true
    }

    func deductVideoSeconds(_ seconds: Int) -> Bool {
        guard videoSeconds >= seconds else { return false }
        videoSeconds -= seconds
        saveCreditsLocally()
        return true
    }

    func refundImageCredit() {
        imageCredits += 1
        saveCreditsLocally()
    }

    func refundVideoSeconds(_ seconds: Int) {
        videoSeconds += seconds
        saveCreditsLocally()
    }

    // MARK: - Persistence

    private func saveCreditsLocally() {
        UserDefaults.standard.set(imageCredits, forKey: "imageCredits")
        UserDefaults.standard.set(videoSeconds, forKey: "videoSeconds")
    }

    func refreshCredits() async {
        // Load from local storage first
        await MainActor.run {
            imageCredits = UserDefaults.standard.integer(forKey: "imageCredits")
            videoSeconds = UserDefaults.standard.integer(forKey: "videoSeconds")
        }

        // TODO: Sync with backend
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                await processTransaction(transaction)
            case .unverified:
                continue
            }
        }
    }
}

// MARK: - Purchase Errors

enum PurchaseError: LocalizedError {
    case verificationFailed
    case cancelled
    case pending
    case unknown

    var errorDescription: String? {
        switch self {
        case .verificationFailed: return "Purchase verification failed."
        case .cancelled: return "Purchase was cancelled."
        case .pending: return "Purchase is pending approval."
        case .unknown: return "An unknown error occurred."
        }
    }
}
