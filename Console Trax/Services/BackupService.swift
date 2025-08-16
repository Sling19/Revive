//
//  BackupService.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
// =====================================================
// Services/BackupService.swift
// =====================================================
import SwiftUI
import SwiftData

struct BackupPackage: Codable {
    var schemaVersion: Int = 1
    var generatedAt: Date = Date()
    var consoles: [ConsoleDTO] = []
    var parts: [PartDTO] = []
    var supplies: [SupplyDTO] = []
}

// DTOs for Codable
struct ConsoleDTO: Codable { var id: UUID, title: String, kind: String, status: String, purchaseSource: String?, pricePaid: Decimal?, condition: String?, sellerURL: String?, salePrice: Decimal?, saleDate: Date?, fees: Decimal?, buyer: String?, startDate: Date?, targetDate: Date?, tags: [String], notes: String, lastActivityAt: Date, createdAt: Date, tasks: [TaskDTO], photos: [PhotoDTO], timeEntries: [TimeDTO], partUses: [UseDTO] }
struct TaskDTO: Codable { var id: UUID, title: String, isDone: Bool, order: Int, dueDate: Date? }
struct PhotoDTO: Codable { var id: UUID, fileName: String, caption: String, createdAt: Date, base64JPEG: String }
struct TimeDTO: Codable { var id: UUID, start: Date, end: Date?, note: String }
struct UseDTO: Codable { var id: UUID, partSKU: String, useQty: Int, costSnapshot: Decimal, notes: String, createdAt: Date, stockDecremented: Bool }
struct PartDTO: Codable { var id: UUID, name: String, brand: String?, sku: String, qtyOnHand: Int, cost: Decimal, notes: String }
struct SupplyDTO: Codable { var id: UUID, name: String, sku: String?, qtyOnHand: Int, costPerUnit: Decimal, reorderThreshold: Int, purchaseURL: String?, notes: String }

@Observable
final class BackupService: ObservableObject {
    private let fileManager = FileManager.default

    // MARK: Paths
    private func documentsURL() -> URL { fileManager.urls(for: .documentDirectory, in: .userDomainMask).first! }
    private func photosDir() -> URL { documentsURL().appendingPathComponent("Photos", isDirectory: true) }

    func ensurePhotoDir() {
        let url = photosDir()
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    func photoPath(fileName: String) -> URL { photosDir().appendingPathComponent(fileName) }

    // MARK: Backup
    func makeBackup(context: ModelContext) throws -> URL {
        let consoles = try context.fetch(FetchDescriptor<Console>())
        let parts = try context.fetch(FetchDescriptor<Part>())
        let supplies = try context.fetch(FetchDescriptor<Supply>())

        var pkg = BackupPackage()
        pkg.consoles = consoles.map { c in
            ConsoleDTO(
                id: c.id, title: c.title, kind: c.kind.rawValue, status: c.status.rawValue,
                purchaseSource: c.purchaseSource, pricePaid: c.pricePaid, condition: c.condition,
                sellerURL: c.sellerURL?.absoluteString, salePrice: c.salePrice, saleDate: c.saleDate, fees: c.fees, buyer: c.buyer,
                startDate: c.startDate, targetDate: c.targetDate, tags: c.tags, notes: c.notes,
                lastActivityAt: c.lastActivityAt, createdAt: c.createdAt,
                tasks: c.tasks.map { TaskDTO(id: $0.id, title: $0.title, isDone: $0.isDone, order: $0.order, dueDate: $0.dueDate) },
                photos: c.photos.map { p in
                    let url = photoPath(fileName: p.fileName)
                    let data = (try? Data(contentsOf: url)) ?? Data()
                    let b64 = data.base64EncodedString()
                    return PhotoDTO(id: p.id, fileName: p.fileName, caption: p.caption, createdAt: p.createdAt, base64JPEG: b64)
                },
                timeEntries: c.timeEntries.map { TimeDTO(id: $0.id, start: $0.start, end: $0.end, note: $0.note) },
                partUses: c.partUses.map { UseDTO(id: $0.id, partSKU: $0.part?.sku ?? "", useQty: $0.useQty, costSnapshot: $0.costSnapshot, notes: $0.notes, createdAt: $0.createdAt, stockDecremented: $0.stockDecremented) }
            )
        }
        pkg.parts = parts.map { PartDTO(id: $0.id, name: $0.name, brand: $0.brand, sku: $0.sku, qtyOnHand: $0.qtyOnHand, cost: $0.cost, notes: $0.notes) }
        pkg.supplies = supplies.map { SupplyDTO(id: $0.id, name: $0.name, sku: $0.sku, qtyOnHand: $0.qtyOnHand, costPerUnit: $0.costPerUnit, reorderThreshold: $0.reorderThreshold, purchaseURL: $0.purchaseURL?.absoluteString, notes: $0.notes) }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(pkg)

        let file = documentsURL().appendingPathComponent("XboxRepairTracker-\(Date().yyyyMMddHHmm).json")
        try data.write(to: file)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastBackupAt")
        return file
    }

    // MARK: Restore (wipe then load)
    func restore(from url: URL, context: ModelContext) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pkg = try decoder.decode(BackupPackage.self, from: data)

        // Wipe
        try wipeAll(context: context)

        // Rebuild
        for pdto in pkg.parts {
            let p = Part(id: pdto.id, name: pdto.name, brand: pdto.brand, sku: pdto.sku, qtyOnHand: pdto.qtyOnHand, cost: pdto.cost, notes: pdto.notes)
            context.insert(p)
        }
        for sdto in pkg.supplies {
            let s = Supply(id: sdto.id, name: sdto.name, sku: sdto.sku, qtyOnHand: sdto.qtyOnHand, costPerUnit: sdto.costPerUnit, reorderThreshold: sdto.reorderThreshold, purchaseURL: sdto.purchaseURL.flatMap(URL.init(string:)), notes: sdto.notes)
            context.insert(s)
        }

        try context.save()

        // We need parts map by SKU for uses
        let partsBySKU = try context.fetch(FetchDescriptor<Part>()).reduce(into: [String: Part]()) { $0[$1.sku] = $1 }

        for cdto in pkg.consoles {
            let c = Console(id: cdto.id, title: cdto.title, kind: Console.Kind(rawValue: cdto.kind) ?? .console, status: Console.Status(rawValue: cdto.status) ?? .incoming, notes: cdto.notes)
            c.purchaseSource = cdto.purchaseSource
            c.pricePaid = cdto.pricePaid
            c.condition = cdto.condition
            c.sellerURL = cdto.sellerURL.flatMap(URL.init(string:))
            c.salePrice = cdto.salePrice
            c.saleDate = cdto.saleDate
            c.fees = cdto.fees
            c.buyer = cdto.buyer
            c.startDate = cdto.startDate
            c.targetDate = cdto.targetDate
            c.tags = cdto.tags
            c.lastActivityAt = cdto.lastActivityAt
            c.createdAt = cdto.createdAt

            // Tasks
            for t in cdto.tasks { c.tasks.append(TaskItem(id: t.id, title: t.title, isDone: t.isDone, order: t.order, dueDate: t.dueDate)) }

            // Photos
            ensurePhotoDir()
            for p in cdto.photos {
                let path = photoPath(fileName: p.fileName)
                if let data = Data(base64Encoded: p.base64JPEG) { try? data.write(to: path) }
                c.photos.append(PhotoAsset(id: p.id, fileName: p.fileName, caption: p.caption))
            }

            // Time
            for te in cdto.timeEntries { c.timeEntries.append(TimeEntry(id: te.id, start: te.start, end: te.end, note: te.note)) }

            // Uses
            for u in cdto.partUses {
                let part = partsBySKU[u.partSKU]
                let use = ConsolePartUse(id: u.id, console: c, part: part, useQty: u.useQty, costSnapshot: u.costSnapshot, notes: u.notes, stockDecremented: u.stockDecremented)
                c.partUses.append(use)
            }

            context.insert(c)
        }

        try context.save()
    }

    func wipeAll(context: ModelContext) throws {
        try context.delete(model: Console.self)
        try context.delete(model: Part.self)
        try context.delete(model: Supply.self)
        try context.delete(model: ConsolePartUse.self)
        try context.delete(model: PhotoAsset.self)
        try context.delete(model: TimeEntry.self)
        try context.delete(model: TaskItem.self)
        try context.save()
    }
}

extension ModelContext {
    func delete<T: PersistentModel>(model: T.Type) throws {
        let all = try fetch(FetchDescriptor<T>())
        for obj in all { delete(obj) }
    }
}

