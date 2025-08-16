//
//  SettingsSheet.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
// ================= Views/Common/SettingsSheet.swift =================
//
//  SettingsSheet.swift
//  Console Trax
//

import SwiftUI
import SwiftData
import Foundation

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var consoles: [Console]

    @AppStorage("backupReminderEnabled") private var backupReminderEnabled: Bool = false

    @State private var exportURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    Toggle("Backup reminder on app close", isOn: $backupReminderEnabled)
                }

                Section("Export") {
                    Button("Export all consoles to CSV") {
                        exportCSV()
                    }
                    if let url = exportURL {
                        // Show a ShareLink once file is ready
                        ShareLink(item: url) {
                            Label("Share CSV", systemImage: "square.and.arrow.up")
                        }
                    }
                }

                Section("About") {
                    Text("Console Trax").font(.headline)
                    Text("Local-first inventory and repair tracker.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Export

    private func exportCSV() {
        let csv = EBayExportService.shared.csv(for: consoles)
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("ConsoleTrax_Export.csv")

        do {
            // Use explicit String.Encoding.utf8 to avoid “cannot infer contextual base” error
            try csv.write(to: tmp, atomically: true, encoding: String.Encoding.utf8)
            exportURL = tmp
        } catch {
            errorMessage = "CSV export failed: \(error.localizedDescription)"
        }
    }
}
