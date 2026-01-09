//
//  CompareView.swift
//  VibeScaler
//

import SwiftUI
import AppKit

struct CompareView: View {
    let originalImage: NSImage
    let processedImage: NSImage
    let onReset: () -> Void

    @State private var sliderPosition: CGFloat = 0.5
    @State private var zoomLevel: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var showOriginalLabel: Bool = true

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

                // Zoom Controls
                HStack(spacing: 16) {
                    Button {
                        withAnimation { zoomLevel = max(0.5, zoomLevel - 0.25) }
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    .vsGhostButton()

                    Text("\(Int(zoomLevel * 100))%")
                        .font(.vsCaption)
                        .foregroundColor(.vsTextSecondary)
                        .frame(width: 50)

                    Button {
                        withAnimation { zoomLevel = min(4.0, zoomLevel + 0.25) }
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .vsGhostButton()

                    Button {
                        withAnimation {
                            zoomLevel = 1.0
                            offset = .zero
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .vsGhostButton()
                }

                Spacer()

                // Export Button
                Button {
                    exportImage()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }
                }
                .vsPrimaryButton()
            }
            .padding(20)

            // Comparison Area
            GeometryReader { geometry in
                ZStack {
                    // Images
                    VSCompareSlider(
                        originalImage: originalImage,
                        processedImage: processedImage,
                        sliderPosition: $sliderPosition
                    )
                    .scaleEffect(zoomLevel)
                    .offset(offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if zoomLevel > 1 {
                                    offset = CGSize(
                                        width: offset.width + value.translation.width / zoomLevel,
                                        height: offset.height + value.translation.height / zoomLevel
                                    )
                                }
                            }
                    )

                    // Labels
                    if showOriginalLabel {
                        VStack {
                            HStack {
                                Label("Original", systemImage: "photo")
                                    .font(.vsCaption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(6)

                                Spacer()

                                Label("Enhanced", systemImage: "wand.and.stars")
                                    .font(.vsCaption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.vsCyan.opacity(0.3))
                                    .cornerRadius(6)
                            }
                            .padding(20)

                            Spacer()
                        }
                        .foregroundColor(.white)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .vsGlassCard()
            }
            .padding(20)

            // Info Bar
            HStack(spacing: 32) {
                InfoItem(
                    label: "Original",
                    value: "\(Int(originalImage.size.width)) × \(Int(originalImage.size.height))"
                )

                Image(systemName: "arrow.right")
                    .foregroundColor(.vsCyan)

                InfoItem(
                    label: "Enhanced",
                    value: "\(Int(processedImage.size.width)) × \(Int(processedImage.size.height))"
                )

                Spacer()

                Toggle("Show Labels", isOn: $showOriginalLabel)
                    .toggleStyle(.switch)
                    .tint(.vsCyan)
            }
            .padding(20)
            .background(Color.vsVoid.opacity(0.5))
        }
    }

    private func exportImage() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff]
        panel.nameFieldStringValue = "enhanced_image.png"

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

struct InfoItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.vsTextMuted)
            Text(value)
                .font(.vsCaption)
                .foregroundColor(.vsTextPrimary)
        }
    }
}

#Preview {
    CompareView(
        originalImage: NSImage(systemSymbolName: "photo", accessibilityDescription: nil)!,
        processedImage: NSImage(systemSymbolName: "photo.fill", accessibilityDescription: nil)!,
        onReset: {}
    )
    .frame(width: 900, height: 700)
    .background(AtmosphericBackground())
    .preferredColorScheme(.dark)
}
