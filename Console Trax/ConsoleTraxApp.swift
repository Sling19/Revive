//
//  ConsoleTraxApp.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
// =========================
// Xbox Repair Tracker (v1)
// SwiftUI + SwiftData • iOS 17+
// Local-first, no CloudKit, modular architecture
// =========================
// Project layout (drop these files into a new Xcode iOS App project):
//
//  XboxRepairTrackerApp.swift
//  Models/Models.swift
//  Services/TimeTrackerService.swift
//  Services/InventoryService.swift
//  Services/BackupService.swift
//  Services/QRService.swift
//  Services/EBayExportService.swift
//  Views/RootTabView.swift
//  Views/Consoles/ConsolesListView.swift
//  Views/Consoles/ConsoleDetailView.swift
//  Views/Parts/PartsView.swift
//  Views/Supplies/SuppliesView.swift
//  Views/Common/SettingsSheet.swift
//  Views/Common/QRScannerView.swift
//  Views/Common/PhotoPickerView.swift
//  Views/Common/PartPickerSheet.swift
//  Utilities/Extensions.swift
//  Utilities/CSV.swift
//
// Add Info.plist keys:
//  - UIFileSharingEnabled = YES
//  - LSSupportsOpeningDocumentsInPlace = YES
//  - CFBundleURLTypes -> URL Schemes: xrt
//      (Identifier: com.consolerevival.XboxRepairTracker, URL Schemes: xrt)
//
// NOTE: This code is intentionally modular and concise. It compiles on Xcode 16.4, iOS 17+.
// Some UI niceties (animations, polish) trimmed for clarity; hooks are in place.

// =====================================================
// XboxRepairTrackerApp.swift
// =====================================================
import SwiftUI
import SwiftData

@main
struct XboxRepairTrackerApp: App {
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - AppStorage
    @AppStorage("hourlyRate") private var hourlyRate: Double = 12.0
    @AppStorage("backupReminderEnabled") private var backupReminderEnabled: Bool = true
    @AppStorage("lastBackupAt") private var lastBackupAt: Double = 0 // timeIntervalSince1970
    @AppStorage("lastWorkedOnConsoleID") private var lastWorkedOnConsoleID: String = ""
    @AppStorage("lastActionText") private var lastActionText: String = ""

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .onOpenURL(perform: handleDeepLink(_:))
                .environment(EBayExportService())
                .environment(InventoryService())
                .environment(TimeTrackerService())
                .environment(BackupService())
        }
        .modelContainer(Self.makeContainer())
        .onChange(of: scenePhase) { _, phase in
            if phase == .inactive || phase == .background {
                // Soft reminder logic; actual notifications can be added later if desired
                if backupReminderEnabled {
                    let day: Double = 24 * 60 * 60
                    let now = Date().timeIntervalSince1970
                    if now - lastBackupAt > day {
                        print("Reminder: Consider backing up from Settings (gear icon).")
                    }
                }
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // The RootTabView listens via .onReceive for Notifications we post here
        guard url.scheme == "xrt" else { return }
        let path = url.host ?? "" // e.g., console
        let comps = url.pathComponents.filter { $0 != "/" }
        guard let idStr = comps.first else { return }

        switch path.lowercased() {
        case "console":
            NotificationCenter.default.post(name: .xrtOpenConsole, object: idStr)
        case "part":
            // part/<uuid>?addTo=<consoleID>
            let q = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let addTo = q?.queryItems?.first(where: { $0.name == "addTo" })?.value
            NotificationCenter.default.post(name: .xrtUsePart, object: ["part": idStr, "console": addTo as Any])
        default:
            break
        }
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([
            Console.self, TaskItem.self, Part.self, ConsolePartUse.self,
            PhotoAsset.self, TimeEntry.self, Supply.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }
}

extension Notification.Name {
    static let xrtOpenConsole = Notification.Name("xrtOpenConsole")
    static let xrtUsePart = Notification.Name("xrtUsePart")
}

