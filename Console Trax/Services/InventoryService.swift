//
//  InventoryService.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
// =====================================================
// Services/InventoryService.swift
// =====================================================
import SwiftUI
import SwiftData

@Observable
final class InventoryService {
    enum UseResult { case decremented, pendingNoStock }

    func attach(part: Part, to console: Console, qty: Int, note: String = "", context: ModelContext) -> UseResult {
        var decremented = false
        if part.qtyOnHand >= qty {
            part.qtyOnHand -= qty
            decremented = true
        }
        let use = ConsolePartUse(console: console, part: part, useQty: qty, costSnapshot: part.cost, notes: note, stockDecremented: decremented)
        console.partUses.append(use)
        console.lastActivityAt = Date()
        context.insert(use)
        try? context.save()
        return decremented ? .decremented : .pendingNoStock
    }

    func remove(use: ConsolePartUse, context: ModelContext) {
        if use.stockDecremented, let part = use.part {
            part.qtyOnHand += use.useQty
        }
        context.delete(use)
        try? context.save()
    }
}

