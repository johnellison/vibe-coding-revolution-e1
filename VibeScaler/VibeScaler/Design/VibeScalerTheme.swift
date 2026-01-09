import SwiftUI

// MARK: - VibeScaler Design System
// Liquid Glass Premium Theme

// ═══════════════════════════════════════════════════════════════
// COLORS
// ═══════════════════════════════════════════════════════════════

extension Color {
    // MARK: - Core Palette
    static let vsVoid = Color(hex: "0a0a0c")
    static let vsAbyss = Color(hex: "111116")
    static let vsSurface = Color(hex: "18181d")
    static let vsElevated = Color(hex: "1e1e24")
    static let vsMuted = Color(hex: "2a2a32")

    // MARK: - Glass Tints
    static let vsGlassWhite = Color.white.opacity(0.03)
    static let vsGlassHighlight = Color.white.opacity(0.08)
    static let vsGlassBorder = Color.white.opacity(0.06)
    static let vsGlassShine = Color.white.opacity(0.12)

    // MARK: - Accent Spectrum
    static let vsCyan = Color(hex: "00d4ff")
    static let vsCyanDeep = Color(hex: "0891b2")
    static let vsCyanMuted = Color(hex: "00d4ff").opacity(0.15)
    static let vsViolet = Color(hex: "a855f7")
    static let vsVioletDeep = Color(hex: "7c3aed")
    static let vsEmerald = Color(hex: "10b981")
    static let vsAmber = Color(hex: "f59e0b")
    static let vsRose = Color(hex: "f43f5e")

    // MARK: - Text Hierarchy
    static let vsTextPrimary = Color.white.opacity(0.95)
    static let vsTextSecondary = Color.white.opacity(0.6)
    static let vsTextTertiary = Color.white.opacity(0.35)
    static let vsTextGhost = Color.white.opacity(0.15)

    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// ═══════════════════════════════════════════════════════════════
// GRADIENTS
// ═══════════════════════════════════════════════════════════════

extension LinearGradient {
    static let vsGlow = LinearGradient(
        colors: [.vsCyan, .vsViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let vsGlowSubtle = LinearGradient(
        colors: [.vsCyan.opacity(0.5), .vsViolet.opacity(0.5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let vsSurfaceGradient = LinearGradient(
        colors: [Color.white.opacity(0.08), Color.clear],
        startPoint: .top,
        endPoint: .bottom
    )

    static let vsShine = LinearGradient(
        colors: [Color.white.opacity(0.12), Color.clear],
        startPoint: .topLeading,
        endPoint: .center
    )
}

// ═══════════════════════════════════════════════════════════════
// TYPOGRAPHY
// ═══════════════════════════════════════════════════════════════

extension Font {
    // Using system fonts for native macOS feel, but styled distinctively
    static let vsHero = Font.system(size: 56, weight: .bold, design: .rounded)
    static let vsTitle = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let vsSubtitle = Font.system(size: 18, weight: .medium, design: .default)
    static let vsBody = Font.system(size: 15, weight: .regular, design: .default)
    static let vsCaption = Font.system(size: 13, weight: .regular, design: .default)
    static let vsMicro = Font.system(size: 11, weight: .semibold, design: .default)
    static let vsMono = Font.system(size: 13, weight: .medium, design: .monospaced)
}

// ═══════════════════════════════════════════════════════════════
// SPACING & RADII
// ═══════════════════════════════════════════════════════════════

enum VSSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

enum VSRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 9999
}

// ═══════════════════════════════════════════════════════════════
// SHADOWS
// ═══════════════════════════════════════════════════════════════

extension View {
    func vsShadowSmall() -> some View {
        self.shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    func vsShadowMedium() -> some View {
        self.shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
    }

    func vsShadowLarge() -> some View {
        self.shadow(color: .black.opacity(0.5), radius: 32, x: 0, y: 16)
    }

    func vsShadowGlow() -> some View {
        self.shadow(color: .vsCyan.opacity(0.3), radius: 20, x: 0, y: 0)
    }
}

// ═══════════════════════════════════════════════════════════════
// GLASS CARD MODIFIER
// ═══════════════════════════════════════════════════════════════

struct GlassCard: ViewModifier {
    var elevated: Bool = false

    func body(content: Content) -> some View {
        content
            .background {
                if elevated {
                    RoundedRectangle(cornerRadius: VSRadius.lg)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: VSRadius.lg)
                                .fill(LinearGradient.vsSurfaceGradient)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: VSRadius.lg)
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                        }
                } else {
                    RoundedRectangle(cornerRadius: VSRadius.lg)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: VSRadius.lg)
                                .strokeBorder(Color.vsGlassBorder, lineWidth: 1)
                        }
                }
            }
    }
}

struct GlassInset: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: VSRadius.md)
                    .fill(Color.black.opacity(0.2))
                    .overlay {
                        RoundedRectangle(cornerRadius: VSRadius.md)
                            .strokeBorder(Color.black.opacity(0.3), lineWidth: 1)
                    }
            }
    }
}

extension View {
    func glassCard(elevated: Bool = false) -> some View {
        modifier(GlassCard(elevated: elevated))
    }

    func glassInset() -> some View {
        modifier(GlassInset())
    }
}

// ═══════════════════════════════════════════════════════════════
// BUTTON STYLES
// ═══════════════════════════════════════════════════════════════

struct VSPrimaryButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.vsBody.weight(.medium))
            .foregroundColor(.vsVoid)
            .padding(.horizontal, VSSpacing.lg)
            .padding(.vertical, VSSpacing.sm)
            .background(LinearGradient.vsGlow)
            .clipShape(RoundedRectangle(cornerRadius: VSRadius.md))
            .overlay {
                RoundedRectangle(cornerRadius: VSRadius.md)
                    .fill(LinearGradient.vsShine)
                    .opacity(isHovered ? 1 : 0)
            }
            .shadow(color: .vsCyan.opacity(0.3), radius: isHovered ? 16 : 8, x: 0, y: isHovered ? 8 : 4)
            .shadow(color: .vsViolet.opacity(0.2), radius: isHovered ? 24 : 12, x: 0, y: isHovered ? 12 : 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .offset(y: isHovered ? -2 : 0)
            .animation(.easeOut(duration: 0.2), value: isHovered)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct VSSecondaryButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.vsBody.weight(.medium))
            .foregroundColor(.vsTextPrimary)
            .padding(.horizontal, VSSpacing.lg)
            .padding(.vertical, VSSpacing.sm)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: VSRadius.md))
            .overlay {
                RoundedRectangle(cornerRadius: VSRadius.md)
                    .strokeBorder(
                        isHovered ? Color.vsGlassShine : Color.vsGlassBorder,
                        lineWidth: 1
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .offset(y: isHovered ? -1 : 0)
            .animation(.easeOut(duration: 0.2), value: isHovered)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct VSGhostButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.vsBody.weight(.medium))
            .foregroundColor(isHovered ? .vsTextPrimary : .vsTextSecondary)
            .padding(.horizontal, VSSpacing.md)
            .padding(.vertical, VSSpacing.sm)
            .background(isHovered ? Color.vsGlassWhite : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: VSRadius.md))
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension ButtonStyle where Self == VSPrimaryButtonStyle {
    static var vsPrimary: VSPrimaryButtonStyle { VSPrimaryButtonStyle() }
}

extension ButtonStyle where Self == VSSecondaryButtonStyle {
    static var vsSecondary: VSSecondaryButtonStyle { VSSecondaryButtonStyle() }
}

extension ButtonStyle where Self == VSGhostButtonStyle {
    static var vsGhost: VSGhostButtonStyle { VSGhostButtonStyle() }
}

// ═══════════════════════════════════════════════════════════════
// GRADIENT TEXT
// ═══════════════════════════════════════════════════════════════

struct GradientText: View {
    let text: String
    let font: Font

    init(_ text: String, font: Font = .vsTitle) {
        self.text = text
        self.font = font
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(LinearGradient.vsGlow)
    }
}

// ═══════════════════════════════════════════════════════════════
// ANIMATED BACKGROUND
// ═══════════════════════════════════════════════════════════════

struct AtmosphericBackground: View {
    @State private var animationPhase: CGFloat = 0

    var body: some View {
        ZStack {
            Color.vsVoid

            // Cyan orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.vsCyan.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .frame(width: 800, height: 800)
                .offset(x: -200, y: -200)
                .offset(x: sin(animationPhase) * 20, y: cos(animationPhase) * 15)

            // Violet orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.vsViolet.opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 350
                    )
                )
                .frame(width: 700, height: 700)
                .offset(x: 250, y: 250)
                .offset(x: cos(animationPhase * 0.8) * 25, y: sin(animationPhase * 0.8) * 20)

            // Emerald accent
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.vsEmerald.opacity(0.06), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: 0, y: 100)
                .offset(x: sin(animationPhase * 1.2) * 15, y: cos(animationPhase * 1.2) * 10)

            // Noise overlay
            Rectangle()
                .fill(.white.opacity(0.02))
                .background {
                    Canvas { context, size in
                        // Simple noise pattern
                        for _ in 0..<500 {
                            let x = CGFloat.random(in: 0...size.width)
                            let y = CGFloat.random(in: 0...size.height)
                            context.fill(
                                Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                                with: .color(.white.opacity(0.1))
                            )
                        }
                    }
                }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                animationPhase = .pi * 2
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// PREVIEW
// ═══════════════════════════════════════════════════════════════

#Preview("VibeScaler Theme") {
    ZStack {
        AtmosphericBackground()

        VStack(spacing: VSSpacing.xl) {
            // Logo
            HStack(spacing: VSSpacing.md) {
                RoundedRectangle(cornerRadius: VSRadius.md)
                    .fill(LinearGradient.vsGlow)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Text("⚡")
                            .font(.title)
                    }

                Text("VibeScaler")
                    .font(.vsTitle)
                    .foregroundColor(.vsTextPrimary)
            }

            // Title
            GradientText("Liquid Glass", font: .vsHero)

            Text("Premium upscaling for creators")
                .font(.vsBody)
                .foregroundColor(.vsTextSecondary)

            // Buttons
            HStack(spacing: VSSpacing.md) {
                Button("Upscale Now") {}
                    .buttonStyle(.vsPrimary)

                Button("Export") {}
                    .buttonStyle(.vsSecondary)

                Button("Settings") {}
                    .buttonStyle(.vsGhost)
            }

            // Glass Card
            VStack(alignment: .leading, spacing: VSSpacing.md) {
                Text("Processing")
                    .font(.vsMicro)
                    .foregroundColor(.vsTextTertiary)
                    .textCase(.uppercase)
                    .tracking(1)

                HStack {
                    RoundedRectangle(cornerRadius: VSRadius.sm)
                        .fill(Color.vsMuted)
                        .frame(width: 56, height: 56)

                    VStack(alignment: .leading, spacing: VSSpacing.xs) {
                        Text("mountain_photo.jpg")
                            .font(.vsBody.weight(.medium))
                            .foregroundColor(.vsTextPrimary)

                        HStack(spacing: VSSpacing.sm) {
                            Circle()
                                .fill(Color.vsCyan)
                                .frame(width: 8, height: 8)

                            Text("Upscaling to 4K...")
                                .font(.vsCaption)
                                .foregroundColor(.vsTextSecondary)
                        }
                    }

                    Spacer()

                    Text("65%")
                        .font(.vsMono)
                        .foregroundColor(.vsCyan)
                }
            }
            .padding(VSSpacing.lg)
            .glassCard(elevated: true)
            .frame(width: 400)
        }
        .padding(VSSpacing.xxxl)
    }
    .frame(width: 800, height: 700)
}
