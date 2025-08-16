//
//  Models.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//

import Foundation
import SwiftData

// =====================================================
// Console
// =====================================================
@Model
final class Console {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case console, controller, accessory
        var id: String { rawValue }
    }

    enum Status: String, Codable, CaseIterable, Identifiable {
        case inProgress = "In Progress"
        case waitingParts = "Waiting Parts"
        case completed = "Completed"
        case sold = "Sold"
        case partsSpares = "Parts/ Spares"
        var id: String { rawValue }
    }

    enum PhysicalGrade: String, Codable, CaseIterable, Identifiable {
        case excellent = "E", good = "G", fair = "D", poor = "P"
        var id: String { rawValue }
    }

    enum TriageStatus: String, Codable, CaseIterable, Identifiable {
        case works = "Works"
        case hasIssues = "Has Issues"
        case notFunctioning = "Not Functioning"
        var id: String { rawValue }
    }

    // Identity & core
    var id: UUID
    var title: String
    var kind: Kind
    var status: Status

    // Standardized check-in
    var serialNumber: String?
    var mfgDate: Date?
    var physicalGrade: PhysicalGrade
    var powerStatus: TriageStatus
    var avStatus: TriageStatus
    var hddStatus: TriageStatus
    var dvdStatus: TriageStatus

    // Purchase
    var purchaseSource: String?
    var pricePaid: Decimal?
    var startDate: Date?

    // Selling
    var askingPrice: Decimal?
    var minPrice: Decimal?
    var soldPrice: Decimal?
    var soldDate: Date?
    var buyer: String?
    var marketplace: String?
    var shippingCost: Decimal?
    var sellingFees: Decimal?
    var sellingNotes: String?

    // Meta
    var tags: [String]
    var notes: String
    var lastActivityAt: Date
    var createdAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade) var tasks: [TaskItem]
    @Relationship(deleteRule: .cascade) var photos: [PhotoAsset]
    @Relationship(deleteRule: .cascade) var timeEntries: [TimeEntry]
    @Relationship(deleteRule: .cascade) var partUses: [ConsolePartUse]

    init(
        id: UUID = UUID(),
        title: String,
        kind: Kind = .console,
        status: Status = .inProgress,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.status = status

        // Defaults for enums must be set in init (SwiftData macro quirk)
        self.physicalGrade = .good
        self.powerStatus = .works
        self.avStatus = .works
        self.hddStatus = .works
        self.dvdStatus = .works

        // Optionals default to nil
        self.serialNumber = nil
        self.mfgDate = nil
        self.purchaseSource = nil
        self.pricePaid = nil
        self.startDate = nil
        self.askingPrice = nil
        self.minPrice = nil
        self.soldPrice = nil
        self.soldDate = nil
        self.buyer = nil
        self.marketplace = nil
        self.shippingCost = nil
        self.sellingFees = nil
        self.sellingNotes = nil

        // Meta
        self.tags = []
        self.notes = notes
        self.lastActivityAt = Date()
        self.createdAt = Date()

        // Relationships start empty
        self.tasks = []
        self.photos = []
        self.timeEntries = []
        self.partUses = []
    }

    var runningEntry: TimeEntry? { timeEntries.first(where: { $0.end == nil }) }
}

// =====================================================
// TaskItem
// =====================================================
@Model
final class TaskItem {
    var id: UUID
    var title: String
    var isDone: Bool
    var order: Int
    var dueDate: Date?

    init(
        id: UUID = UUID(),
        title: String,
        isDone: Bool = false,
        order: Int = 0,
        dueDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.order = order
        self.dueDate = dueDate
    }
}

// =====================================================
// Part
// =====================================================
@Model
final class Part {
    var id: UUID
    var name: String
    var brand: String?
    var sku: String
    var qtyOnHand: Int
    var cost: Decimal
    var notes: String

    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        sku: String,
        qtyOnHand: Int = 0,
        cost: Decimal = 0,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.sku = sku
        self.qtyOnHand = qtyOnHand
        self.cost = cost
        self.notes = notes
    }
}

// =====================================================
// ConsolePartUse
// =====================================================
@Model
final class ConsolePartUse {
    var id: UUID
    @Relationship var console: Console?
    @Relationship var part: Part?
    var useQty: Int
    var costSnapshot: Decimal
    var notes: String
    var createdAt: Date
    var stockDecremented: Bool

    init(
        id: UUID = UUID(),
        console: Console? = nil,
        part: Part? = nil,
        useQty: Int,
        costSnapshot: Decimal,
        notes: String = "",
        stockDecremented: Bool = false
    ) {
        self.id = id
        self.console = console
        self.part = part
        self.useQty = useQty
        self.costSnapshot = costSnapshot
        self.notes = notes
        self.createdAt = Date()
        self.stockDecremented = stockDecremented
    }
}

// =====================================================
// PhotoAsset
// =====================================================
@Model
final class PhotoAsset {
    var id: UUID
    var fileName: String
    var caption: String
    var createdAt: Date

    init(id: UUID = UUID(), fileName: String, caption: String = "") {
        self.id = id
        self.fileName = fileName
        self.caption = caption
        self.createdAt = Date()
    }
}

// =====================================================
// TimeEntry
// =====================================================
@Model
final class TimeEntry {
    var id: UUID
    var start: Date
    var end: Date?
    var note: String

    init(
        id: UUID = UUID(),
        start: Date = Date(),
        end: Date? = nil,
        note: String = ""
    ) {
        self.id = id
        self.start = start
        self.end = end
        self.note = note
    }
}

// =====================================================
// Supply
// =====================================================
@Model
final class Supply {
    var id: UUID
    var name: String
    var sku: String?
    var qtyOnHand: Int
    var costPerUnit: Decimal
    var reorderThreshold: Int
    var purchaseURL: URL?
    var notes: String

    init(
        id: UUID = UUID(),
        name: String,
        sku: String? = nil,
        qtyOnHand: Int = 0,
        costPerUnit: Decimal = 0,
        reorderThreshold: Int = 0,
        purchaseURL: URL? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.sku = sku
        self.qtyOnHand = qtyOnHand
        self.costPerUnit = costPerUnit
        self.reorderThreshold = reorderThreshold
        self.purchaseURL = purchaseURL
        self.notes = notes
    }
}
