//
//  StoreView.swift
//  VibeScaler
//

import SwiftUI
import StoreKit

struct StoreView: View {
    @EnvironmentObject var creditManager: CreditManager
    @State private var selectedTab: StoreTab = .images
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    enum StoreTab: String, CaseIterable {
        case images = "Image Credits"
        case video = "Video Credits"
        case pro = "Pro Plan"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Store")
                            .font(.vsTitle)
                            .foregroundColor(.vsTextPrimary)

                        Text("Purchase credits for AI-enhanced upscaling")
                            .font(.vsCaption)
                            .foregroundColor(.vsTextMuted)
                    }

                    Spacer()

                    VSCreditBadge(
                        imageCredits: creditManager.imageCredits,
                        videoMinutes: creditManager.videoMinutes
                    )
                }

                // Tab Selector
                HStack(spacing: 4) {
                    ForEach(StoreTab.allCases, id: \.self) { tab in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTab = tab
                            }
                        } label: {
                            Text(tab.rawValue)
                                .font(.vsCaption)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selectedTab == tab ?
                                    Color.vsCyan.opacity(0.2) : Color.clear
                                )
                                .foregroundColor(
                                    selectedTab == tab ? .vsCyan : .vsTextSecondary
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .vsGlassCard()
            }
            .padding(24)

            Divider()
                .background(Color.vsGlassBorder)

            // Content
            ScrollView {
                switch selectedTab {
                case .images:
                    ImageCreditsSection(creditManager: creditManager, onPurchase: purchase)
                case .video:
                    VideoCreditsSection(creditManager: creditManager, onPurchase: purchase)
                case .pro:
                    ProPlanSection(creditManager: creditManager, onPurchase: purchase)
                }
            }
            .padding(24)

            // Footer
            HStack {
                Button("Restore Purchases") {
                    Task {
                        try? await creditManager.restorePurchases()
                    }
                }
                .vsGhostButton()

                Spacer()

                Text("Secure payments via App Store")
                    .font(.system(size: 11))
                    .foregroundColor(.vsTextMuted)
            }
            .padding(24)
            .background(Color.vsVoid.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func purchase(_ product: Product) {
        Task {
            isLoading = true
            do {
                try await creditManager.purchase(product)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Image Credits Section

struct ImageCreditsSection: View {
    @ObservedObject var creditManager: CreditManager
    let onPurchase: (Product) -> Void

    private var imageProducts: [Product] {
        creditManager.products.filter {
            $0.id.contains("credits")
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Hero
            VStack(spacing: 8) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.vsCyan, .vsViolet],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("AI Image Enhancement")
                    .font(.vsSubtitle)
                    .foregroundColor(.vsTextPrimary)

                Text("Each credit enhances one image with AI clarity")
                    .font(.vsCaption)
                    .foregroundColor(.vsTextMuted)
            }
            .padding(.bottom, 16)

            // Products
            ForEach(imageProducts, id: \.id) { product in
                CreditPackCard(product: product) {
                    onPurchase(product)
                }
            }

            // Local Option
            VStack(spacing: 8) {
                Divider()
                    .background(Color.vsGlassBorder)

                HStack {
                    Image(systemName: "cpu")
                        .foregroundColor(.vsTextMuted)

                    Text("Standard upscaling (local) is always free")
                        .font(.system(size: 12))
                        .foregroundColor(.vsTextMuted)
                }
            }
            .padding(.top, 16)
        }
    }
}

// MARK: - Video Credits Section

struct VideoCreditsSection: View {
    @ObservedObject var creditManager: CreditManager
    let onPurchase: (Product) -> Void

    private var videoProducts: [Product] {
        creditManager.products.filter {
            $0.id.contains("video")
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Hero
            VStack(spacing: 8) {
                Image(systemName: "film.stack")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.vsViolet, .vsCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("AI Video Upscaling")
                    .font(.vsSubtitle)
                    .foregroundColor(.vsTextPrimary)

                Text("Upscale video to stunning 4K resolution")
                    .font(.vsCaption)
                    .foregroundColor(.vsTextMuted)
            }
            .padding(.bottom, 16)

            // Products
            ForEach(videoProducts, id: \.id) { product in
                CreditPackCard(product: product) {
                    onPurchase(product)
                }
            }
        }
    }
}

// MARK: - Pro Plan Section

struct ProPlanSection: View {
    @ObservedObject var creditManager: CreditManager
    let onPurchase: (Product) -> Void

    private var proProduct: Product? {
        creditManager.products.first { $0.id.contains("pro") }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Hero Card
            VStack(spacing: 16) {
                HStack {
                    Text("CREATOR PRO")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.vsCyan)

                    Spacer()

                    Text("Best Value")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.vsVoid)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.vsCyan)
                        .cornerRadius(4)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$19.99")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.vsTextPrimary)

                    Text("/month")
                        .font(.vsBody)
                        .foregroundColor(.vsTextMuted)

                    Spacer()
                }

                Divider()
                    .background(Color.vsGlassBorder)

                // Features
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "photo.stack", text: "75 AI image credits per month")
                    FeatureRow(icon: "film.stack", text: "5 minutes AI video per month")
                    FeatureRow(icon: "arrow.clockwise", text: "Unused credits roll over")
                    FeatureRow(icon: "bolt", text: "Priority processing queue")
                    FeatureRow(icon: "star", text: "Early access to new features")
                }

                if let product = proProduct {
                    Button {
                        onPurchase(product)
                    } label: {
                        HStack {
                            Text("Subscribe Now")
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .vsPrimaryButton()
                }

                Text("Cancel anytime. Billed monthly.")
                    .font(.system(size: 11))
                    .foregroundColor(.vsTextMuted)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.vsCyan.opacity(0.1),
                                Color.vsViolet.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.vsCyan.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Credit Pack Card

struct CreditPackCard: View {
    let product: Product
    let onPurchase: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: product.id.contains("video") ? "film" : "photo")
                .font(.system(size: 24))
                .foregroundColor(.vsCyan)
                .frame(width: 50, height: 50)
                .background(Color.vsCyan.opacity(0.1))
                .cornerRadius(12)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.vsBody)
                    .foregroundColor(.vsTextPrimary)

                Text(product.description)
                    .font(.system(size: 12))
                    .foregroundColor(.vsTextMuted)
            }

            Spacer()

            // Price
            Button(action: onPurchase) {
                Text(product.displayPrice)
                    .font(.vsCaption)
            }
            .vsSecondaryButton()
        }
        .padding(16)
        .vsGlassCard()
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.vsCyan)
                .frame(width: 20)

            Text(text)
                .font(.vsCaption)
                .foregroundColor(.vsTextPrimary)
        }
    }
}

#Preview {
    StoreView()
        .environmentObject(CreditManager())
        .frame(width: 600, height: 700)
        .background(AtmosphericBackground())
        .preferredColorScheme(.dark)
}
