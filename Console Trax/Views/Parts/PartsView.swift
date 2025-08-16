//
//  PartsView.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
// ================= Views/Parts/PartsView.swift =================
import SwiftUI
import SwiftData

struct PartsView: View {
    @Environment(\.modelContext) private var context
    @Query private var parts: [Part]
    @State private var search = ""
    @State private var showNew = false
    @State private var showSettings = false

    init() { _parts = Query(FetchDescriptor<Part>()) }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered(parts)) { p in
                    VStack(alignment: .leading) {
                        HStack { Text(p.name).font(.headline); Spacer(); Text(p.cost.currency) }
                        Text("SKU: \(p.sku)  •  On hand: \(p.qtyOnHand)").font(.caption).foregroundStyle(.secondary)
                        if let brand = p.brand, !brand.isEmpty { Text(brand).font(.caption2) }
                    }
                    .contextMenu { Button("Generate QR") { shareQR(for: p) } }
                }.onDelete(perform: delete)
            }
            .navigationTitle("Parts")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { showSettings = true } label: { Image(systemName: "gearshape") } }
                ToolbarItem(placement: .topBarTrailing) { Button { showNew = true } label: { Image(systemName: "plus") } }
            }
            .searchable(text: $search)
            .sheet(isPresented: $showNew) { NewPartSheet() }
            .sheet(isPresented: $showSettings) { SettingsSheet() }
        }
    }

    private func filtered(_ arr: [Part]) -> [Part] { search.isEmpty ? arr : arr.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.sku.localizedCaseInsensitiveContains(search) } }
    private func delete(at offsets: IndexSet) { for i in offsets { context.delete(filtered(parts)[i]) }; try? context.save() }

    private func shareQR(for part: Part) {
        let url = "xrt://part/\(part.id.uuidString)"
        if let img = QRService().makeQRCode(from: url) {
            let av = UIActivityViewController(activityItems: [img], applicationActivities: nil)
            UIApplication.shared.topMost?.present(av, animated: true)
        }
    }
}

