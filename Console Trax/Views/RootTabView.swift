//
//  RootTabView.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
// =====================================================
// Views/RootTabView.swift
// =====================================================
import SwiftUI
import SwiftData

private struct ConsoleSelection: Identifiable { let id: String }

struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(BackupService.self) private var backup
    @Environment(EBayExportService.self) private var ebay

    @State private var openConsole: ConsoleSelection? = nil

    var body: some View {
        TabView {
            ConsolesListView()
                .tabItem { Label("Work", systemImage: "wrench.and.screwdriver") }
            PartsView()
                .tabItem { Label("Parts", systemImage: "shippingbox") }
            SuppliesView()
                .tabItem { Label("Supplies", systemImage: "tray.full") }
        }
        .onReceive(NotificationCenter.default.publisher(for: .xrtOpenConsole)) { note in
            if let id = note.object as? String { openConsole = .init(id: id) }
        }
        .sheet(item: $openConsole) { sel in
            if
                let uuid = UUID(uuidString: sel.id),
                let console = try? context
                    .fetch(FetchDescriptor<Console>(predicate: #Predicate { $0.id == uuid }))
                    .first
            {
                ConsoleDetailView(console: console)
            } else {
                Text("Console not found").padding()
            }
        }
    }
}
