//
//  EBayExportService.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
// =====================================================
// Services/EBayExportService.swift
// =====================================================

import Foundation
import SwiftData

/// Minimal, safe export that matches the updated Console model.
/// - Maps `physicalGrade` -> human-readable condition text
/// - Uses `soldPrice` if present; else falls back to `askingPrice`
@MainActor
final class EBayExportService {
    static let shared = EBayExportService()
    private init() {}

    /// Build a CSV string for all consoles (simple, eBay-friendly columns).
    /// You can tweak headers/columns later without breaking compile.
    func csv(for consoles: [Console]) -> String {
        let headers = [
            "SKU",                // using Console.title (e.g., XBX-101)
            "Title",              // same as SKU for now
            "ConditionDescription",
            "Price",
            "Quantity",
            "Marketplace",
            "Buyer",
            "SoldDate",
            "ShippingCost",
            "Fees",
            "Notes"
        ]

        var rows: [[String]] = [headers]

        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 2
        nf.maximumFractionDigits = 2

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        for c in consoles {
            let sku = c.title
            let title = c.title

            let conditionText = Self.condition(from: c.physicalGrade)

            // Prefer soldPrice; otherwise use askingPrice; otherwise blank
            let priceDec: Decimal? = c.soldPrice ?? c.askingPrice
            let priceStr = priceDec.flatMap { nf.string(from: NSDecimalNumber(decimal: $0)) } ?? ""

            let qty = "1"
            let marketplace = c.marketplace ?? ""
            let buyer = c.buyer ?? ""
            let soldDate = c.soldDate.map { df.string(from: $0) } ?? ""
            let shipping = c.shippingCost.flatMap { nf.string(from: NSDecimalNumber(decimal: $0)) } ?? ""
            let fees = c.sellingFees.flatMap { nf.string(from: NSDecimalNumber(decimal: $0)) } ?? ""
            let notes = c.sellingNotes ?? ""

            rows.append([
                sku,
                title,
                conditionText,
                priceStr,
                qty,
                marketplace,
                buyer,
                soldDate,
                shipping,
                fees,
                notes
            ])
        }

        return Self.makeCSV(rows)
    }

    // MARK: - Helpers

    private static func condition(from grade: Console.PhysicalGrade) -> String {
        switch grade {
        case .excellent: return "Excellent"
        case .good:      return "Good"
        case .fair:      return "Fair"
        case .poor:      return "Poor"
        }
    }

    /// Tiny CSV builder (quotes fields with commas/quotes/newlines).
    private static func makeCSV(_ rows: [[String]]) -> String {
        rows.map { row in
            row.map { field in
                if field.contains(",") || field.contains("\"") || field.contains("\n") {
                    let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
                    return "\"\(escaped)\""
                } else {
                    return field
                }
            }.joined(separator: ",")
        }.joined(separator: "\n") + "\n"
    }
}
