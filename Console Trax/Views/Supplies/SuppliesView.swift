//
//  SuppliesView.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
//================= Views/Supplies/SuppliesView.swift =================
import SwiftUI
import SwiftData

struct SuppliesView: View {
    @Environment(\.modelContext) private var context
    @Query private var supplies: [Supply]
    @State private var search: String = ""
    @State private var showNew = false
    @State private var showSettings = false

    init() { _supplies = Query(FetchDescriptor<Supply>()) }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered(supplies)) { s in
                    VStack(alignment: .leading) {
                        HStack { Text(s.name).font(.headline); Spacer(); Text(s.costPerUnit.currency) }
                        Text("SKU: \(s.sku ?? "-") • On hand: \(s.qtyOnHand)").font(.caption).foregroundStyle(.secondary)
                    }
                }.onDelete(perform: delete)
            }
            .navigationTitle("Supplies")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { showSettings = true } label: { Image(systemName: "gearshape") } }
                ToolbarItem(placement: .topBarTrailing) { Button { showNew = true } label: { Image(systemName: "plus") } }
            }
            .searchable(text: $search)
            .sheet(isPresented: $showNew) { NewSupplySheet() }
            .sheet(isPresented: $showSettings) { SettingsSheet() }
        }
    }

    private func filtered(_ arr: [Supply]) -> [Supply] {
        guard !search.isEmpty else { return arr }
        return arr.filter {
            $0.name.localizedCaseInsensitiveContains(search)
            || ($0.sku ?? "").localizedCaseInsensitiveContains(search)
        }
    }

    private func delete(at offsets: IndexSet) { for i in offsets { context.delete(filtered(supplies)[i]) }; try? context.save() }
}

struct NewSupplySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var sku = ""
    @State private var qty = 0
    @State private var cost: Decimal = 0
    @State private var threshold = 0
    @State private var url = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("SKU", text: $sku)
                Stepper("Qty On Hand: \(qty)", value: $qty)
                TextField("Cost/Unit", value: $cost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                Stepper("Reorder Alert at: \(threshold)", value: $threshold)
                TextField("Purchase URL", text: $url)
            }
            .navigationTitle("New Supply")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { save() }.disabled(name.isEmpty) }
            }
        }
    }

    private func save() {
        let s = Supply(name: name, sku: sku.isEmpty ? nil : sku, qtyOnHand: qty, costPerUnit: cost, reorderThreshold: threshold, purchaseURL: URL(string: url), notes: "")
        context.insert(s)
        try? context.save()
        dismiss()
    }
}

