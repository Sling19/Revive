//
//  PartPickerSheet.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
// ================= Views/Common/PartPickerSheet.swift =================
import SwiftUI
import SwiftData

struct PartPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(InventoryService.self) private var inventory
    var console: Console

    @Query private var parts: [Part]
    @State private var search: String = ""
    @State private var qty: Int = 1
    @State private var showNew = false

    init(console: Console) { self.console = console; _parts = Query(FetchDescriptor<Part>()) }

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(filtered(parts)) { p in
                        Button { attach(p) } label: {
                            HStack { VStack(alignment: .leading) { Text(p.name); Text("SKU: \(p.sku) – On hand: \(p.qtyOnHand)").font(.caption).foregroundStyle(.secondary) }; Spacer(); Text(p.cost.currency) }
                        }
                    }
                }
            }
            .navigationTitle("Pick a Part")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button { showNew = true } label: { Label("New", systemImage: "plus") } }
                ToolbarItem(placement: .bottomBar) { Stepper("Qty: \(qty)", value: $qty, in: 1...50) }
            }
            .searchable(text: $search)
            .sheet(isPresented: $showNew) { NewPartSheet() }
        }
    }

    private func filtered(_ arr: [Part]) -> [Part] { search.isEmpty ? arr : arr.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.sku.localizedCaseInsensitiveContains(search) } }

    private func attach(_ part: Part) {
        let result = inventory.attach(part: part, to: console, qty: qty, context: context)
        if case .pendingNoStock = result { print("Attached without stock; consider creating inventory record.") }
        dismiss()
    }
}

struct NewPartSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var brand = ""
    @State private var sku = ""
    @State private var qty = 0
    @State private var cost: Decimal = 0

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Brand", text: $brand)
                TextField("SKU (unique)", text: $sku)
                Stepper("Qty On Hand: \(qty)", value: $qty)
                TextField("Cost", value: $cost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
            }
            .navigationTitle("New Part")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { save() }.disabled(name.isEmpty || sku.isEmpty) }
            }
        }
    }

    private func save() {
        // Enforce unique SKU
        if (try? context.fetch(FetchDescriptor<Part>(predicate: #Predicate { $0.sku == sku })).first) != nil {
            print("Duplicate SKU not allowed")
            return
        }

        let p = Part(name: name, brand: brand.isEmpty ? nil : brand, sku: sku, qtyOnHand: qty, cost: cost)
        context.insert(p)
        try? context.save()
        dismiss()
    }
}

