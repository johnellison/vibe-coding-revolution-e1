//
//  ContentView.swift
//  VibeScaler
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var creditManager: CreditManager
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // Logo
                HStack(spacing: 12) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.vsCyan, .vsViolet],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("VibeScaler")
                        .font(.vsTitle)
                        .foregroundColor(.vsTextPrimary)
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)

                Divider()
                    .background(Color.vsGlassBorder)

                // Navigation Items
                VStack(spacing: 4) {
                    ForEach(AppState.NavigationItem.allCases, id: \.self) { item in
                        SidebarButton(
                            title: item.rawValue,
                            icon: iconForItem(item),
                            isSelected: appState.currentView == item
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                appState.currentView = item
                            }
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 12)

                Spacer()

                // Credit Badge
                if authService.isAuthenticated {
                    VSCreditBadge(
                        imageCredits: creditManager.imageCredits,
                        videoMinutes: creditManager.videoMinutes
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }

                // User Section
                UserSection()
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
            }
            .frame(minWidth: 220, maxWidth: 260)
            .background(Color.vsVoid.opacity(0.5))

        } detail: {
            // Main Content
            ZStack {
                switch appState.currentView {
                case .upscale:
                    UpscaleView()
                case .removeBackground:
                    RemoveBackgroundView()
                case .history:
                    HistoryView()
                case .store:
                    StoreView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $appState.showPurchaseSheet) {
            StoreView()
                .frame(minWidth: 500, minHeight: 600)
        }
        .alert("Error", isPresented: $appState.showError) {
            Button("OK") {
                appState.errorMessage = nil
            }
        } message: {
            Text(appState.errorMessage ?? "An unknown error occurred")
        }
    }

    private func iconForItem(_ item: AppState.NavigationItem) -> String {
        switch item {
        case .upscale: return "arrow.up.left.and.arrow.down.right"
        case .removeBackground: return "person.crop.rectangle.stack"
        case .history: return "clock.arrow.circlepath"
        case .store: return "creditcard"
        }
    }
}

// MARK: - Sidebar Button

struct SidebarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 24)

                Text(title)
                    .font(.vsBody)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.vsCyan.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.vsCyan.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .foregroundColor(isSelected ? .vsCyan : .vsTextSecondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - User Section

struct UserSection: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        if authService.isAuthenticated {
            HStack(spacing: 10) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.vsCyan, .vsViolet],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(authService.userInitials)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(authService.userName)
                        .font(.vsCaption)
                        .foregroundColor(.vsTextPrimary)
                    Text("Pro Account")
                        .font(.system(size: 10))
                        .foregroundColor(.vsTextMuted)
                }

                Spacer()

                Button {
                    // Settings
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .foregroundColor(.vsTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .vsGlassCard()
        } else {
            Button {
                authService.signInWithApple()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                    Text("Sign in with Apple")
                        .font(.vsCaption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .vsPrimaryButton()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(CreditManager())
        .environmentObject(AuthService())
        .frame(width: 1200, height: 800)
        .background(AtmosphericBackground())
        .preferredColorScheme(.dark)
}
