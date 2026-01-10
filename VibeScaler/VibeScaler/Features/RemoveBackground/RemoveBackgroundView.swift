//
//  RemoveBackgroundView.swift
//  VibeScaler
//
//  Background removal UI
//

import SwiftUI
import UniformTypeIdentifiers

struct RemoveBackgroundView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var creditManager: CreditManager
    @StateObject private var viewModel = RemoveBackgroundViewModel()

    var body: some View {
        ZStack {
            if viewModel.hasResult {
                // Show result comparison
                BackgroundResultView(
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
                MainRemoveBackgroundView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.4), value: viewModel.hasResult)
        .animation(.spring(response: 0.4), value: viewModel.isProcessing)
    }
}

// MARK: - Main View

struct MainRemoveBackgroundView: View {
    @ObservedObject var viewModel: RemoveBackgroundViewModel
    @EnvironmentObject var creditManager: CreditManager

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("Remove Background")
                    .font(.vsHero)
                    .foregroundColor(.vsTextPrimary)

                Text("AI-powered background removal with transparency")
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
                RemoveBackgroundOptionsPanel(viewModel: viewModel)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // Remove Button
            if viewModel.selectedFile != nil {
                Button {
                    Task {
                        await viewModel.startRemoval()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "wand.and.rays")
                        Text("Remove Background (1 Credit)")
                    }
                    .frame(minWidth: 220)
                }
                .vsPrimaryButton()
                .disabled(!creditManager.hasImageCredits)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(48)
    }
}

// MARK: - Options Panel

struct RemoveBackgroundOptionsPanel: View {
    @ObservedObject var viewModel: RemoveBackgroundViewModel

    var body: some View {
        VStack(spacing: 20) {
            // File Info
            HStack {
                Image(systemName: "photo")
                    .foregroundColor(.vsViolet)
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

            // Model Selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Removal Model")
                    .font(.vsCaption)
                    .foregroundColor(.vsTextMuted)

                HStack(spacing: 12) {
                    ForEach(BackgroundRemovalModel.allCases, id: \.self) { model in
                        ModelOptionCard(
                            model: model,
                            isSelected: viewModel.selectedModel == model
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.selectedModel = model
                            }
                        }
                    }
                }
            }

            // Model Info
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.vsTextMuted)

                Text(viewModel.selectedModel.description)
                    .font(.system(size: 12))
                    .foregroundColor(.vsTextSecondary)

                Spacer()

                Text(viewModel.selectedModel.estimatedCost)
                    .font(.vsCaption)
                    .foregroundColor(.vsViolet)
            }
        }
        .frame(maxWidth: 600)
    }
}

// MARK: - Model Option Card

struct ModelOptionCard: View {
    let model: BackgroundRemovalModel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: model.icon)
                    .font(.system(size: 20))

                Text(model.displayName)
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.vsViolet.opacity(0.2) : Color.vsGraphite.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.vsViolet.opacity(0.5) : Color.vsGlassBorder, lineWidth: 1)
            )
            .foregroundColor(isSelected ? .vsViolet : .vsTextSecondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Background Result View

struct BackgroundResultView: View {
    let originalImage: NSImage
    let processedImage: NSImage
    let onReset: () -> Void

    @State private var showOriginal: Bool = false
    @State private var backgroundColor: Color = .clear

    let backgroundOptions: [Color] = [
        .clear,
        .white,
        .black,
        Color(red: 0.2, green: 0.2, blue: 0.2),
        .blue,
        .green
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    onReset()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                        Text("New Image")
                    }
                }
                .vsGhostButton()

                Spacer()

                // Background Color Picker
                HStack(spacing: 8) {
                    Text("Preview BG:")
                        .font(.vsCaption)
                        .foregroundColor(.vsTextMuted)

                    ForEach(backgroundOptions, id: \.self) { color in
                        Button {
                            backgroundColor = color
                        } label: {
                            Circle()
                                .fill(color == .clear ?
                                    AnyShapeStyle(checkerboard) :
                                    AnyShapeStyle(color))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            backgroundColor == color ? Color.vsCyan : Color.vsGlassBorder,
                                            lineWidth: 2
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                // Export Button
                Button {
                    exportImage()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export PNG")
                    }
                }
                .vsPrimaryButton()
            }
            .padding(20)

            // Image Preview
            GeometryReader { geometry in
                ZStack {
                    // Background
                    if backgroundColor == .clear {
                        checkerboard
                    } else {
                        backgroundColor
                    }

                    // Image
                    Image(nsImage: showOriginal ? originalImage : processedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(40)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .vsGlassCard()
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in showOriginal = true }
                        .onEnded { _ in showOriginal = false }
                )
            }
            .padding(20)

            // Info Bar
            HStack(spacing: 32) {
                Text("Hold to see original")
                    .font(.vsCaption)
                    .foregroundColor(.vsTextMuted)

                Spacer()

                Label("Transparent PNG", systemImage: "checkmark.circle.fill")
                    .font(.vsCaption)
                    .foregroundColor(.vsViolet)
            }
            .padding(20)
            .background(Color.vsVoid.opacity(0.5))
        }
    }

    private var checkerboard: some ShapeStyle {
        // Checkerboard pattern for transparency
        ImagePaint(
            image: Image(systemName: "checkerboard.rectangle")
                .renderingMode(.template),
            scale: 0.1
        )
        .foregroundColor(Color.gray.opacity(0.3))
    }

    private func exportImage() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "image_no_bg.png"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                if let tiffData = processedImage.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiffData) {
                    let pngData = bitmap.representation(using: .png, properties: [:])
                    try? pngData?.write(to: url)
                }
            }
        }
    }
}

#Preview {
    RemoveBackgroundView()
        .environmentObject(AppState())
        .environmentObject(CreditManager())
        .frame(width: 900, height: 700)
        .background(AtmosphericBackground())
        .preferredColorScheme(.dark)
}
