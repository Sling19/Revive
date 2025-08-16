//
//  ConsoleDetailView.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
// ================= Views/Consoles/ConsoleDetailView.swift =================
import SwiftUI
import SwiftData

struct ConsoleDetailView: View {
    @Environment(\.modelContext) private var context

    let consoleID: UUID
    @Query private var matches: [Console]

    init(consoleID: UUID) {
        self.consoleID = consoleID
        _matches = Query(FetchDescriptor<Console>(predicate: #Predicate { $0.id == consoleID }))
    }

    var body: some View {
        Group {
            if let c = matches.first {
                Form {
                    Section("Basics") {
                        TextField("Title", text: bind(c, \.title))
                        Picker("Kind", selection: bind(c, \.kind)) {
                            ForEach(Console.Kind.allCases) { Text($0.rawValue.capitalized).tag($0) }
                        }
                        TextField("Serial Number", text: bind(c, \.serialNumber, default: ""))
                        DatePicker("Date of Manufacture",
                                   selection: bind(c, \.mfgDate, default: Date()),
                                   displayedComponents: .date)
                        Picker("Physical Grade", selection: bind(c, \.physicalGrade)) {
                            ForEach(Console.PhysicalGrade.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Picker("Status", selection: bind(c, \.status)) {
                            ForEach(Console.Status.allCases) { Text($0.rawValue).tag($0) }
                        }
                    }

                    Section("Diagnostics") {
                        Picker("Power", selection: bind(c, \.powerStatus)) {
                            ForEach(Console.TriageStatus.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Picker("AV", selection: bind(c, \.avStatus)) {
                            ForEach(Console.TriageStatus.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Picker("HDD", selection: bind(c, \.hddStatus)) {
                            ForEach(Console.TriageStatus.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Picker("DVD", selection: bind(c, \.dvdStatus)) {
                            ForEach(Console.TriageStatus.allCases) { Text($0.rawValue).tag($0) }
                        }
                    }

                    Section("Purchase") {
                        TextField("Source", text: bind(c, \.purchaseSource, default: ""))
                        DecimalField(title: "Price Paid", value: opt(c, \.pricePaid))
                        DatePicker("Purchase Date",
                                   selection: bind(c, \.startDate, default: Date()),
                                   displayedComponents: .date)
                    }

                    Section("Selling") {
                        DecimalField(title: "Asking Price", value: opt(c, \.askingPrice))
                        DecimalField(title: "Min Price", value: opt(c, \.minPrice))
                        DecimalField(title: "Sold Price", value: opt(c, \.soldPrice))
                        DatePicker("Sold Date",
                                   selection: bind(c, \.soldDate, default: Date()),
                                   displayedComponents: .date)
                        TextField("Buyer", text: bind(c, \.buyer, default: ""))
                        TextField("Marketplace", text: bind(c, \.marketplace, default: ""))
                        DecimalField(title: "Shipping Cost", value: opt(c, \.shippingCost))
                        DecimalField(title: "Fees", value: opt(c, \.sellingFees))
                        TextField("Selling Notes", text: bind(c, \.sellingNotes, default: ""))
                    }

                    Section("Notes") {
                        TextEditor(text: bind(c, \.notes))
                            .frame(minHeight: 120)
                    }
                }
                .navigationTitle(c.title)
            } else {
                Text("Console not found.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Binding helpers (no @$results nonsense)
private func bind<T>(_ console: Console, _ keyPath: ReferenceWritableKeyPath<Console, T>) -> Binding<T> {
    Binding(
        get: { console[keyPath: keyPath] },
        set: { console[keyPath: keyPath] = $0 }
    )
}

private func bind<T>(_ console: Console, _ keyPath: ReferenceWritableKeyPath<Console, T?>, default defaultValue: @autoclosure @escaping () -> T) -> Binding<T> {
    Binding(
        get: { console[keyPath: keyPath] ?? defaultValue() },
        set: { console[keyPath: keyPath] = $0 }
    )
}

private func opt<T>(_ console: Console, _ keyPath: ReferenceWritableKeyPath<Console, T?>) -> Binding<T?> {
    Binding(
        get: { console[keyPath: keyPath] },
        set: { console[keyPath: keyPath] = $0 }
    )
}
