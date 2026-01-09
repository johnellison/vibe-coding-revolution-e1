//
//  UpscaleView.swift
//  VibeScaler
//

import SwiftUI
import UniformTypeIdentifiers

struct UpscaleView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var creditManager: CreditManager
    @StateObject private var viewModel = UpscaleViewModel()

    var body: some View {
        ZStack {
            if viewModel.hasResult {
                // Show comparison view
                CompareView(
                    originalImage: viewModel.originalImage!,
                    processedImage: viewModel.processedImage!,
                    onReset: { viewModel.reset() }
                )
            } else if viewModel.isProcessing {
                // Show processing state
                ProcessingView(
                    fileName: viewModel.selectedFile?.lastPathComponent ?? "Image",
                    progress: viewModel.progress,
                    status: viewModel.statusMessage,
                    onCancel: { viewModel.cancel() }
                )
            } else {
                // Show drop zone
                MainUpscaleView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.4), value: viewModel.hasResult)
        .animation(.spring(response: 0.4), value: viewModel.isProcessing)
    }
}

// MARK: - Main Upscale View

struct MainUpscaleView: View {
    @ObservedObject var viewModel: UpscaleViewModel
    @EnvironmentObject var creditManager: CreditManager

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("Upscale Your Media")
                    .font(.vsHero)
                    .foregroundColor(.vsTextPrimary)

                Text("Drop an image or video to enhance resolution")
                    .font(.vsBody)
                    .foregroundColor(.vsTextSecondary)
            }

            // Drop Zone
            VSDropZone(
                isTargeted: $viewModel.isDropTargeted,
                supportedTypes: viewModel.supportedTypes
            ) { urls in
                viewModel.handleDrop(urls: urls)
            }
            .frame(maxWidth: 600, maxHeight: 350)

            // Options
            if viewModel.selectedFile != nil {
                OptionsPanel(viewModel: viewModel)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // Upscale Button
            if viewModel.selectedFile != nil {
                Button {
                    Task {
                        await viewModel.startUpscale()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                        Text(viewModel.selectedModel.requiresCredits ? "Upscale (1 Credit)" : "Upscale (Free)")
                    }
                    .frame(minWidth: 200)
                }
                .vsPrimaryButton()
                .disabled(!canUpscale)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(48)
    }

    private var canUpscale: Bool {
        guard viewModel.selectedFile != nil else { return false }
        if viewModel.selectedModel.requiresCredits {
            return creditManager.hasImageCredits
        }
        return true
    }
}

// MARK: - Options Panel

struct OptionsPanel: View {
    @ObservedObject var viewModel: UpscaleViewModel

    var body: some View {
        VStack(spacing: 20) {
            // File Info
            HStack {
                Image(systemName: "photo")
                    .foregroundColor(.vsCyan)
                Text(viewModel.selectedFile?.lastPathComponent ?? "")
                    .font(.vsCaption)
                    .foregroundColor(.vsTextPrimary)

                Spacer()

                if let size = viewModel.originalDimensions {
                    Text("\(Int(size.width)) × \(Int(size.height))")
                        .font(.vsCaption)
                        .foregroundColor(.vsTextMuted)
                }

                Button {
                    viewModel.reset()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.vsTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .vsGlassCard()

            // Model & Scale Selectors
            HStack(spacing: 16) {
                // Model Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enhancement")
                        .font(.vsCaption)
                        .foregroundColor(.vsTextMuted)

                    VSPresetSelector(
                        selected: $viewModel.selectedModel,
                        options: UpscaleModel.allCases
                    ) { model in
                        Text(model.displayName)
                    }
                }

                // Scale Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scale")
                        .font(.vsCaption)
                        .foregroundColor(.vsTextMuted)

                    VSScaleSelector(
                        selected: $viewModel.selectedScale,
                        options: ScaleFactor.allCases
                    )
                }

                // Quality Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quality")
                        .font(.vsCaption)
                        .foregroundColor(.vsTextMuted)

                    VSPresetSelector(
                        selected: $viewModel.selectedQuality,
                        options: QualityPreset.allCases
                    ) { preset in
                        HStack(spacing: 4) {
                            Image(systemName: preset.icon)
                            Text(preset.displayName)
                        }
                    }
                }
            }

            // Output Preview
            if let size = viewModel.originalDimensions {
                let newWidth = Int(size.width) * viewModel.selectedScale.rawValue
                let newHeight = Int(size.height) * viewModel.selectedScale.rawValue

                HStack {
                    Text("Output: \(newWidth) × \(newHeight)")
                        .font(.vsCaption)
                        .foregroundColor(.vsTextSecondary)

                    Spacer()

                    Text(viewModel.selectedModel.description)
                        .font(.system(size: 11))
                        .foregroundColor(.vsTextMuted)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: 600)
    }
}

// MARK: - Processing View

struct ProcessingView: View {
    let fileName: String
    let progress: Double
    let status: String
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            // Animated Icon
            ZStack {
                Circle()
                    .fill(Color.vsCyan.opacity(0.1))
                    .frame(width: 120, height: 120)

                Circle()
                    .stroke(Color.vsCyan.opacity(0.3), lineWidth: 3)
                    .frame(width: 100, height: 100)

                VSProgressCircle(progress: progress, size: 100)

                Image(systemName: "wand.and.stars")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.vsCyan, .vsViolet],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Processing...")
                    .font(.vsTitle)
                    .foregroundColor(.vsTextPrimary)

                Text(fileName)
                    .font(.vsCaption)
                    .foregroundColor(.vsTextSecondary)

                Text(status)
                    .font(.vsCaption)
                    .foregroundColor(.vsCyan)
                    .padding(.top, 4)
            }

            VSProgressBar(progress: progress)
                .frame(maxWidth: 300)

            Button("Cancel") {
                onCancel()
            }
            .vsGhostButton()
        }
        .padding(48)
    }
}

#Preview {
    UpscaleView()
        .environmentObject(AppState())
        .environmentObject(CreditManager())
        .frame(width: 900, height: 700)
        .background(AtmosphericBackground())
        .preferredColorScheme(.dark)
}
