import SwiftUI
import UniformTypeIdentifiers

// ═══════════════════════════════════════════════════════════════
// DROP ZONE COMPONENT
// ═══════════════════════════════════════════════════════════════

struct VSDropZone: View {
    let onDrop: ([URL]) -> Void
    @State private var isTargeted = false
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: VSSpacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: VSRadius.lg)
                    .fill(LinearGradient.vsGlow)
                    .frame(width: 64, height: 64)
                    .shadow(color: .vsCyan.opacity(0.4), radius: 16, x: 0, y: 8)

                Image(systemName: "arrow.up.doc.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.vsVoid)
            }
            .scaleEffect(isTargeted ? 1.1 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTargeted)

            // Text
            VStack(spacing: VSSpacing.xs) {
                Text("Drop images or videos here")
                    .font(.vsSubtitle)
                    .foregroundColor(.vsTextPrimary)

                Text("or click to browse")
                    .font(.vsCaption)
                    .foregroundColor(.vsTextSecondary)
            }

            // Format badges
            HStack(spacing: VSSpacing.sm) {
                FormatBadge("JPEG")
                FormatBadge("PNG")
                FormatBadge("HEIC")
                FormatBadge("WebP")
                FormatBadge("MP4")
                FormatBadge("MOV")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VSSpacing.xxxl)
        .padding(.horizontal, VSSpacing.xl)
        .background {
            RoundedRectangle(cornerRadius: VSRadius.xl)
                .fill(isTargeted ? Color.vsCyan.opacity(0.05) : Color.vsGlassWhite)
                .overlay {
                    RoundedRectangle(cornerRadius: VSRadius.xl)
                        .strokeBorder(
                            isTargeted ? Color.clear : Color.vsGlassBorder,
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                }
                .overlay {
                    if isTargeted {
                        RoundedRectangle(cornerRadius: VSRadius.xl)
                            .strokeBorder(LinearGradient.vsGlow, lineWidth: 2)
                            .opacity(0.8)
                    }
                }
        }
        .scaleEffect(isTargeted ? 1.02 : (isHovered ? 1.01 : 1))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTargeted)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
        .onTapGesture {
            openFilePicker()
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        var urls: [URL] = []
        let group = DispatchGroup()

        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    urls.append(url)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            onDrop(urls)
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .jpeg, .png, .heic, .webP, .tiff,
            .mpeg4Movie, .quickTimeMovie, .avi
        ]

        if panel.runModal() == .OK {
            onDrop(panel.urls)
        }
    }
}

struct FormatBadge: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.5)
            .foregroundColor(.vsTextTertiary)
            .padding(.horizontal, VSSpacing.sm)
            .padding(.vertical, VSSpacing.xs)
            .background {
                RoundedRectangle(cornerRadius: VSRadius.sm)
                    .fill(Color.vsGlassWhite)
                    .overlay {
                        RoundedRectangle(cornerRadius: VSRadius.sm)
                            .strokeBorder(Color.vsGlassBorder, lineWidth: 1)
                    }
            }
    }
}

// ═══════════════════════════════════════════════════════════════
// BEFORE/AFTER COMPARISON SLIDER
// ═══════════════════════════════════════════════════════════════

struct VSCompareSlider: View {
    let beforeImage: NSImage?
    let afterImage: NSImage?
    @State private var sliderPosition: CGFloat = 0.5
    @GestureState private var isDragging = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // After image (full)
                if let afterImage {
                    Image(nsImage: afterImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }

                // Before image (clipped)
                if let beforeImage {
                    Image(nsImage: beforeImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .clipShape(
                            Rectangle()
                                .offset(x: -geometry.size.width * (1 - sliderPosition))
                        )
                        .mask(
                            HStack(spacing: 0) {
                                Rectangle()
                                    .frame(width: geometry.size.width * sliderPosition)
                                Spacer(minLength: 0)
                            }
                        )
                }

                // Divider line
                Rectangle()
                    .fill(.white)
                    .frame(width: 2)
                    .position(x: geometry.size.width * sliderPosition, y: geometry.size.height / 2)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 0)

                // Handle
                VSCompareHandle()
                    .position(x: geometry.size.width * sliderPosition, y: geometry.size.height / 2)
                    .scaleEffect(isDragging ? 1.1 : 1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)

                // Labels
                VStack {
                    Spacer()
                    HStack {
                        CompareLabel("ORIGINAL")
                            .padding(.leading, VSSpacing.md)

                        Spacer()

                        CompareLabel("4× UPSCALED")
                            .padding(.trailing, VSSpacing.md)
                    }
                    .padding(.bottom, VSSpacing.md)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: VSRadius.xl))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        let newPosition = value.location.x / geometry.size.width
                        sliderPosition = min(max(newPosition, 0), 1)
                    }
            )
        }
        .aspectRatio(16/10, contentMode: .fit)
        .background(Color.vsSurface)
        .clipShape(RoundedRectangle(cornerRadius: VSRadius.xl))
    }
}

struct VSCompareHandle: View {
    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: 48, height: 48)
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
            .overlay {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.vsVoid)
            }
    }
}

struct CompareLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .tracking(1)
            .foregroundColor(.white)
            .padding(.horizontal, VSSpacing.md)
            .padding(.vertical, VSSpacing.xs)
            .background {
                Capsule()
                    .fill(.black.opacity(0.6))
                    .background(.ultraThinMaterial, in: Capsule())
            }
    }
}

// ═══════════════════════════════════════════════════════════════
// PROGRESS INDICATORS
// ═══════════════════════════════════════════════════════════════

struct VSProgressBar: View {
    let progress: Double
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: VSRadius.full)
                    .fill(Color.vsGlassWhite)

                // Fill
                RoundedRectangle(cornerRadius: VSRadius.full)
                    .fill(LinearGradient.vsGlow)
                    .frame(width: geometry.size.width * progress)

                // Shimmer
                RoundedRectangle(cornerRadius: VSRadius.full)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * 0.3)
                    .offset(x: shimmerOffset * geometry.size.width)
                    .mask {
                        RoundedRectangle(cornerRadius: VSRadius.full)
                            .frame(width: geometry.size.width * progress)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
            }
        }
        .frame(height: 6)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.3
            }
        }
    }
}

struct VSProgressCircle: View {
    let progress: Double
    var size: CGFloat = 48
    var lineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.vsGlassWhite, lineWidth: lineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient.vsGlow,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.3), value: progress)

            // Percentage text
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.25, weight: .semibold, design: .monospaced))
                .foregroundColor(.vsTextPrimary)
        }
        .frame(width: size, height: size)
    }
}

// ═══════════════════════════════════════════════════════════════
// PROCESSING CARD
// ═══════════════════════════════════════════════════════════════

struct VSProcessingCard: View {
    let fileName: String
    let thumbnail: NSImage?
    let progress: Double
    let status: String
    var onCancel: (() -> Void)? = nil

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: VSSpacing.md) {
            // Thumbnail
            Group {
                if let thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.vsMuted)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: VSRadius.md))

            // Info
            VStack(alignment: .leading, spacing: VSSpacing.xs) {
                Text(fileName)
                    .font(.vsBody.weight(.medium))
                    .foregroundColor(.vsTextPrimary)
                    .lineLimit(1)

                HStack(spacing: VSSpacing.sm) {
                    // Pulsing dot
                    Circle()
                        .fill(Color.vsCyan)
                        .frame(width: 8, height: 8)
                        .modifier(PulseAnimation())

                    Text(status)
                        .font(.vsCaption)
                        .foregroundColor(.vsTextSecondary)
                }
            }

            Spacer()

            // Progress or Cancel
            if progress < 1 {
                VSProgressCircle(progress: progress, size: 40, lineWidth: 3)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(LinearGradient.vsGlow)
            }

            // Cancel button (on hover)
            if isHovered && progress < 1, let onCancel {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.vsTextSecondary)
                        .frame(width: 24, height: 24)
                        .background(Color.vsGlassWhite, in: Circle())
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(VSSpacing.md)
        .glassCard()
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1 : 0.8)
            .opacity(isPulsing ? 1 : 0.6)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

// ═══════════════════════════════════════════════════════════════
// CREDIT BADGE
// ═══════════════════════════════════════════════════════════════

struct VSCreditBadge: View {
    let imageCredits: Int
    let videoMinutes: Double
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: VSSpacing.md) {
            // Image credits
            HStack(spacing: VSSpacing.sm) {
                Circle()
                    .fill(LinearGradient.vsGlow)
                    .frame(width: 20, height: 20)
                    .overlay {
                        Text("⚡")
                            .font(.system(size: 10))
                    }

                Text("\(imageCredits)")
                    .font(.vsBody.weight(.semibold))
                    .foregroundColor(.vsTextPrimary)

                Text("credits")
                    .font(.vsCaption)
                    .foregroundColor(.vsTextTertiary)
            }

            Divider()
                .frame(height: 16)

            // Video time
            HStack(spacing: VSSpacing.sm) {
                Circle()
                    .fill(Color.vsViolet)
                    .frame(width: 20, height: 20)
                    .overlay {
                        Text("🎬")
                            .font(.system(size: 10))
                    }

                Text(formatVideoTime(videoMinutes))
                    .font(.vsBody.weight(.semibold))
                    .foregroundColor(.vsTextPrimary)

                Text("video")
                    .font(.vsCaption)
                    .foregroundColor(.vsTextTertiary)
            }
        }
        .padding(.horizontal, VSSpacing.md)
        .padding(.vertical, VSSpacing.sm)
        .background {
            Capsule()
                .fill(Color.vsGlassWhite)
                .overlay {
                    Capsule()
                        .strokeBorder(Color.vsGlassBorder, lineWidth: 1)
                }
        }
        .onTapGesture {
            onTap?()
        }
    }

    private func formatVideoTime(_ minutes: Double) -> String {
        let mins = Int(minutes)
        let secs = Int((minutes - Double(mins)) * 60)
        return String(format: "%d:%02d", mins, secs)
    }
}

// ═══════════════════════════════════════════════════════════════
// PRESET SELECTOR
// ═══════════════════════════════════════════════════════════════

enum UpscalePreset: String, CaseIterable {
    case standard = "Standard"
    case enhanced = "Enhanced"
    case maximum = "Maximum"
}

struct VSPresetSelector: View {
    @Binding var selection: UpscalePreset

    var body: some View {
        HStack(spacing: VSSpacing.xs) {
            ForEach(UpscalePreset.allCases, id: \.self) { preset in
                Button(action: { selection = preset }) {
                    Text(preset.rawValue)
                        .font(.vsCaption.weight(.medium))
                        .foregroundColor(selection == preset ? .vsVoid : .vsTextSecondary)
                        .padding(.horizontal, VSSpacing.md)
                        .padding(.vertical, VSSpacing.sm)
                        .background {
                            if selection == preset {
                                RoundedRectangle(cornerRadius: VSRadius.md)
                                    .fill(LinearGradient.vsGlow)
                                    .shadow(color: .vsCyan.opacity(0.3), radius: 8, x: 0, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(VSSpacing.xs)
        .background {
            RoundedRectangle(cornerRadius: VSRadius.lg)
                .fill(Color.vsGlassWhite)
                .overlay {
                    RoundedRectangle(cornerRadius: VSRadius.lg)
                        .strokeBorder(Color.vsGlassBorder, lineWidth: 1)
                }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selection)
    }
}

// ═══════════════════════════════════════════════════════════════
// SCALE SELECTOR
// ═══════════════════════════════════════════════════════════════

enum UpscaleScale: Int, CaseIterable {
    case x2 = 2
    case x4 = 4
    case x8 = 8

    var label: String { "\(rawValue)×" }
}

struct VSScaleSelector: View {
    @Binding var selection: UpscaleScale

    var body: some View {
        HStack(spacing: VSSpacing.sm) {
            ForEach(UpscaleScale.allCases, id: \.self) { scale in
                VSScaleOption(scale: scale, isSelected: selection == scale) {
                    selection = scale
                }
            }
        }
    }
}

struct VSScaleOption: View {
    let scale: UpscaleScale
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(scale.label)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isSelected ? .vsVoid : .vsTextPrimary)

                Text("SCALE")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(isSelected ? .vsVoid.opacity(0.7) : .vsTextTertiary)
            }
            .frame(width: 56, height: 56)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: VSRadius.md)
                        .fill(LinearGradient.vsGlow)
                        .shadow(color: .vsCyan.opacity(0.4), radius: 12, x: 0, y: 4)
                } else {
                    RoundedRectangle(cornerRadius: VSRadius.md)
                        .fill(Color.vsGlassWhite)
                        .overlay {
                            RoundedRectangle(cornerRadius: VSRadius.md)
                                .strokeBorder(Color.vsGlassBorder, lineWidth: 1)
                        }
                }
            }
            .scaleEffect(isHovered && !isSelected ? 1.05 : 1)
            .offset(y: isHovered && !isSelected ? -2 : 0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// PREVIEW
// ═══════════════════════════════════════════════════════════════

#Preview("Components") {
    ZStack {
        AtmosphericBackground()

        ScrollView {
            VStack(spacing: VSSpacing.xl) {
                // Drop Zone
                VSDropZone { urls in
                    print("Dropped: \(urls)")
                }
                .frame(height: 250)

                // Presets
                HStack(spacing: VSSpacing.xl) {
                    VStack(alignment: .leading, spacing: VSSpacing.sm) {
                        Text("QUALITY")
                            .font(.vsMicro)
                            .foregroundColor(.vsTextTertiary)
                            .tracking(1)

                        VSPresetSelector(selection: .constant(.enhanced))
                    }

                    VStack(alignment: .leading, spacing: VSSpacing.sm) {
                        Text("SCALE")
                            .font(.vsMicro)
                            .foregroundColor(.vsTextTertiary)
                            .tracking(1)

                        VSScaleSelector(selection: .constant(.x4))
                    }
                }

                // Progress
                VStack(spacing: VSSpacing.md) {
                    VSProgressBar(progress: 0.65)

                    HStack {
                        VSProgressCircle(progress: 0.42)
                        VSProgressCircle(progress: 0.78, size: 64, lineWidth: 5)
                        VSProgressCircle(progress: 1.0)
                    }
                }

                // Processing Card
                VSProcessingCard(
                    fileName: "mountain_landscape_4k.jpg",
                    thumbnail: nil,
                    progress: 0.65,
                    status: "Upscaling to 4K..."
                )

                // Credits
                VSCreditBadge(imageCredits: 47, videoMinutes: 5.5)

                // Buttons
                HStack {
                    Button("Upscale Now") {}
                        .buttonStyle(.vsPrimary)

                    Button("Export") {}
                        .buttonStyle(.vsSecondary)
                }
            }
            .padding(VSSpacing.xl)
        }
    }
    .frame(width: 600, height: 900)
}
