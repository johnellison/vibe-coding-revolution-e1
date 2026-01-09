//
//  HistoryView.swift
//  VibeScaler
//

import SwiftUI
import AppKit

struct HistoryView: View {
    @StateObject private var historyManager = HistoryManager()
    @State private var selectedEntry: HistoryEntry?
    @State private var searchText: String = ""

    var filteredEntries: [HistoryEntry] {
        if searchText.isEmpty {
            return historyManager.entries
        }
        return historyManager.entries.filter {
            $0.originalFileName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("History")
                        .font(.vsTitle)
                        .foregroundColor(.vsTextPrimary)

                    Text("\(historyManager.entries.count) processed files")
                        .font(.vsCaption)
                        .foregroundColor(.vsTextMuted)
                }

                Spacer()

                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.vsTextMuted)

                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.vsBody)
                }
                .padding(10)
                .frame(width: 200)
                .vsGlassCard()

                if !historyManager.entries.isEmpty {
                    Button {
                        historyManager.clearHistory()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Clear")
                        }
                    }
                    .vsGhostButton()
                }
            }
            .padding(24)

            Divider()
                .background(Color.vsGlassBorder)

            // Content
            if historyManager.entries.isEmpty {
                EmptyHistoryView()
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(filteredEntries) { entry in
                            HistoryCard(entry: entry) {
                                selectedEntry = entry
                            }
                            .contextMenu {
                                Button {
                                    NSWorkspace.shared.activateFileViewerSelecting([entry.processedURL])
                                } label: {
                                    Label("Show in Finder", systemImage: "folder")
                                }

                                Button {
                                    NSWorkspace.shared.open(entry.processedURL)
                                } label: {
                                    Label("Open", systemImage: "arrow.up.forward.square")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    historyManager.removeEntry(entry)
                                } label: {
                                    Label("Remove from History", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - History Card

struct HistoryCard: View {
    let entry: HistoryEntry
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Thumbnail
                ZStack {
                    if let thumbnail = entry.thumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.vsGraphite)
                        Image(systemName: entry.fileType == .video ? "video" : "photo")
                            .font(.system(size: 32))
                            .foregroundColor(.vsTextMuted)
                    }
                }
                .frame(height: 140)
                .clipped()

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.originalFileName)
                        .font(.vsCaption)
                        .foregroundColor(.vsTextPrimary)
                        .lineLimit(1)

                    HStack {
                        Text(entry.processedSize)
                            .font(.system(size: 11))
                            .foregroundColor(.vsTextMuted)

                        Spacer()

                        Text(entry.modelName)
                            .font(.system(size: 10))
                            .foregroundColor(.vsCyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.vsCyan.opacity(0.15))
                            .cornerRadius(4)
                    }

                    Text(entry.formattedDate)
                        .font(.system(size: 10))
                        .foregroundColor(.vsTextMuted)
                }
                .padding(12)
            }
            .vsGlassCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.vsCyan.opacity(0.5), .vsViolet.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("No History Yet")
                .font(.vsTitle)
                .foregroundColor(.vsTextPrimary)

            Text("Processed files will appear here")
                .font(.vsBody)
                .foregroundColor(.vsTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HistoryView()
        .frame(width: 900, height: 700)
        .background(AtmosphericBackground())
        .preferredColorScheme(.dark)
}
