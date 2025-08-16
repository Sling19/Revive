//
//  ConsolesListView.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
// =====================================================
// Views/Consoles/ConsolesListView.swift
// =====================================================

import SwiftUI
import SwiftData

struct ConsolesListView: View {
    @Environment(\.modelContext) private var context
    @Environment(TimeTrackerService.self) private var timeTracker
    @Environment(InventoryService.self) private var inventory
    @Environment(BackupService.self) private var backup

    @AppStorage("lastWorkedOnConsoleID") private var lastWorkedOnConsoleID: String = ""
    @AppStorage("lastActionText") private var lastActionText: String = ""

    enum SortMode: String, CaseIterable, Identifiable { case runningFirst, lastWorkedFirst; var id: String { rawValue } }

    @State private var sortMode: SortMode = .runningFirst
    @State private var searchText: String = ""
    @State private var statusFilters: Set<Console.Status> = []
    @State private var showNew = false
    @State private var showSettings = false

    @Query private var allConsoles: [Console]

    init() {
        _allConsoles = Query(FetchDescriptor<Console>())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                if !lastWorkedOnConsoleID.isEmpty,
                   let c = allConsoles.first(where: { $0.id.uuidString == lastWorkedOnConsoleID }) {
                    HStack(spacing: 6) {
                        Text("Last project worked on — ").italic()
                        Text("\(lastActionText) on \(c.title)").italic().fontWeight(.medium)
                        Spacer()
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                }

                List {
                    ForEach(sorted(filtered(searched(allConsoles)))) { c in
                        ConsoleRow(console: c)
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Consoles & Controllers")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .principal) {
                    Picker("Sort", selection: $sortMode) {
                        Text("Running First").tag(SortMode.runningFirst)
                        Text("Last Worked First").tag(SortMode.lastWorkedFirst)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 320)
                }
            }
            .searchable(text: $searchText)
            .safeAreaInset(edge: .top) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Console.Status.allCases) { s in
                            let selected = statusFilters.contains(s)
                            Text(s.rawValue.capitalized)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(selected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.15))
                                .clipShape(Capsule())
                                .onTapGesture { toggleFilter(s) }
                        }
                    }
                    .padding(.horizontal).padding(.bottom, 6)
                }
                .background(.ultraThinMaterial)
            }
            .sheet(isPresented: $showNew) { NewConsoleSheet() }
            .sheet(isPresented: $showSettings) { SettingsSheet() }
        }
    }

    private func toggleFilter(_ s: Console.Status) {
        if statusFilters.contains(s) { statusFilters.remove(s) } else { statusFilters.insert(s) }
    }

    private func searched(_ list: [Console]) -> [Console] {
        guard !searchText.isEmpty else { return list }
        return list.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func filtered(_ list: [Console]) -> [Console] {
        guard !statusFilters.isEmpty else { return list }
        return list.filter { statusFilters.contains($0.status) }
    }

    private func sorted(_ list: [Console]) -> [Console] {
        switch sortMode {
        case .runningFirst:
            return list.sorted { a, b in
                let aRun = a.runningEntry != nil
                let bRun = b.runningEntry != nil
                if aRun != bRun { return aRun && !bRun }
                return a.lastActivityAt > b.lastActivityAt
            }
        case .lastWorkedFirst:
            return list.sorted { $0.lastActivityAt > $1.lastActivityAt }
        }
    }

    private func delete(at offsets: IndexSet) {
        for idx in offsets {
            context.delete(sorted(filtered(searched(allConsoles)))[idx])
        }
        try? context.save()
    }
}

struct ConsoleRow: View {
    @Environment(\.modelContext) private var context
    @Environment(TimeTrackerService.self) private var timeTracker

    @AppStorage("lastWorkedOnConsoleID") private var lastWorkedOnConsoleID: String = ""
    @AppStorage("lastActionText") private var lastActionText: String = ""

    @State var console: Console

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle().fill(console.runningEntry == nil ? Color.secondary.opacity(0.3) : .green)
                .frame(width: 10, height: 10)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 6) {
                Text(console.title).font(.headline)
                HStack(spacing: 8) {
                    Text(console.status.rawValue.capitalized)
                    Text(timeTracker.totalSeconds(for: console).asHMS).monospacedDigit()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: toggleTimer) {
                Label(console.runningEntry == nil ? "Start" : "Stop",
                      systemImage: console.runningEntry == nil ? "play.fill" : "stop.fill")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { openDetail() }
    }

    private func toggleTimer() {
        if console.runningEntry == nil {
            timeTracker.start(console: console, context: context)
            lastWorkedOnConsoleID = console.id.uuidString
            lastActionText = "Started timer"
        } else {
            timeTracker.stop(console: console, context: context)
            lastWorkedOnConsoleID = console.id.uuidString
            lastActionText = "Stopped timer"
        }
    }

    private func openDetail() {
        NotificationCenter.default.post(name: .xrtOpenConsole, object: console.id.uuidString)
    }
}

// MARK: - New Console Sheet
struct NewConsoleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var unitNumber: String = ""
    @State private var kind: Console.Kind = .console
    @State private var serialNumber: String = ""
    @State private var mfgDate: Date = Date()
    @State private var physicalGrade: Console.PhysicalGrade = .good

    @State private var powerStatus: Console.TriageStatus = .works
    @State private var avStatus: Console.TriageStatus = .works
    @State private var hddStatus: Console.TriageStatus = .works
    @State private var dvdStatus: Console.TriageStatus = .works

    @State private var purchaseSource: String = ""
    @State private var pricePaid: Decimal?
    @State private var purchaseDate: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Console") {
                    TextField("Unit # (auto-suggested)", text: $unitNumber)
                    Picker("Type", selection: $kind) {
                        ForEach(Console.Kind.allCases) { Text($0.rawValue.capitalized).tag($0) }
                    }
                    TextField("Serial Number", text: $serialNumber)
                    DatePicker("Date of Manufacture", selection: $mfgDate, displayedComponents: .date)
                    Picker("Physical Grade", selection: $physicalGrade) {
                        ForEach(Console.PhysicalGrade.allCases) { Text($0.rawValue).tag($0) }
                    }
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
            .onAppear { suggestNextUnitNumber() }
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

        [
            "Open case","Inspect clock cap","DVD drive test","Replace thermal paste",
            "Clean shell","Polish jewel","SMART check HDD","Final test"
        ].enumerated().forEach { idx, t in
            c.tasks.append(TaskItem(title: t, order: idx))
        }

        context.insert(c)
        try? context.save()
        dismiss()
    }

    private func suggestNextUnitNumber() {
        let fetch = FetchDescriptor<Console>()
        if let consoles = try? context.fetch(fetch) {
            let existing = consoles.compactMap { $0.title }
            let prefix = "XBX-"
            let maxNum = existing.compactMap { t in
                if t.hasPrefix(prefix), let n = Int(t.dropFirst(prefix.count)) { return n }
                return nil
            }.max() ?? 100
            unitNumber = "\(prefix)\(maxNum + 1)"
        } else {
            unitNumber = "XBX-101"
        }
    }
}
