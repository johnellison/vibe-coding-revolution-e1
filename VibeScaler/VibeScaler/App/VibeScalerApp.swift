//
//  VibeScalerApp.swift
//  VibeScaler
//
//  AI-powered image and video upscaling
//

import SwiftUI

@main
struct VibeScalerApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var creditManager = CreditManager()
    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(creditManager)
                .environmentObject(authService)
                .background(AtmosphericBackground())
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Image...") {
                    appState.showFilePicker = true
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - App State

class AppState: ObservableObject {
    @Published var currentView: NavigationItem = .upscale
    @Published var showFilePicker: Bool = false
    @Published var isProcessing: Bool = false
    @Published var processingProgress: Double = 0
    @Published var selectedFiles: [URL] = []
    @Published var processedFiles: [ProcessedFile] = []
    @Published var showPurchaseSheet: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    enum NavigationItem: String, CaseIterable {
        case upscale = "Upscale"
        case removeBackground = "Remove BG"
        case history = "History"
        case store = "Store"
    }
}

// MARK: - Processed File

struct ProcessedFile: Identifiable {
    let id = UUID()
    let originalURL: URL
    let processedURL: URL
    let originalSize: CGSize
    let processedSize: CGSize
    let processingType: ProcessingType
    let timestamp: Date

    enum ProcessingType: String {
        case local = "Standard"
        case aiEnhanced = "AI Enhanced"
    }
}
