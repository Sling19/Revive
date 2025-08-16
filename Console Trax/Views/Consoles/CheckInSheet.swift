//
//  CheckInSheet.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
//
//  CheckInSheet.swift
//  Console Trax
//

import SwiftUI
import SwiftData

struct CheckInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var unitNumber = ""
    @State private var kind: Console.Kind = .console
    @State private var serialNumber = ""
    @State private var mfgDate = Date()
    @State private var physicalGrade: Console.PhysicalGrade = .good

    @State private var powerStatus: Console.TriageStatus = .works
    @State private var avStatus: Console.TriageStatus = .works
    @State private var hddStatus: Console.TriageStatus = .works
    @State private var dvdStatus: Console.TriageStatus = .works

    @State private var purchaseSource = ""
    @State private var pricePaid: Decimal?
    @State private var purchaseDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Console") {
                    TextField("Unit #", text: $unitNumber)
                    Picker("Type", selection: $kind) { ForEach(Console.Kind.allCases) { Text($0.rawValue.capitalized).tag($0) } }
                    TextField("Serial Number", text: $serialNumber)
                    DatePicker("Date of Manufacture", selection: $mfgDate, displayedComponents: .date)
                    Picker("Physical Grade", selection: $physicalGrade) { ForEach(Console.PhysicalGrade.allCases) { Text($0.rawValue).tag($0) } }
                }
                Section("Quick Diagnostics") {
                    Picker("Power", selection: $powerStatus) { ForEach(Console.TriageStatus.allCases) { Text($0.rawValue).tag($0) } }
                    Picker("AV", selection: $avStatus) { ForEach(Console.TriageStatus.allCases) { Text($0.rawValue).tag($0) } }
                    Picker("HDD", selection: $hddStatus) { ForEach(Console.TriageStatus.allCases) { Text($0.rawValue).tag($0) } }
                    Picker("DVD", selection: $dvdStatus) { ForEach(Console.TriageStatus.allCases) { Text($0.rawValue).tag($0) } }
                }
                Section("Purchase (optional)") {
                    TextField("Source", text: $purchaseSource)
                    DecimalField(title: "Price Paid", value: $pricePaid)
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Check In Console")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { add() }.disabled(unitNumber.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
        }
    }

    private func add() {
        let c = Console(title: unitNumber, kind: kind)
        c.serialNumber = serialNumber.isEmpty ? nil : serialNumber
        c.mfgDate = mfgDate
        c.physicalGrade = physicalGrade
        c.powerStatus = powerStatus
        c.avStatus = avStatus
        c.hddStatus = hddStatus
        c.dvdStatus = dvdStatus
        c.purchaseSource = purchaseSource.isEmpty ? nil : purchaseSource
        c.pricePaid = pricePaid
        c.startDate = purchaseDate
        context.insert(c)
        try? context.save()
        dismiss()
    }
}
