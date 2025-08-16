//
//  TimeTrackerService.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
// =====================================================
// Services/TimeTrackerService.swift
// =====================================================
import SwiftUI
import SwiftData

@Observable
final class TimeTrackerService {
    func start(console: Console, context: ModelContext) {
        // Prevent overlapping entries on the same console
        if console.runningEntry != nil { return }
        let entry = TimeEntry()
        console.timeEntries.append(entry)
        console.lastActivityAt = Date()
        context.insert(entry)
        try? context.save()
    }

    func stop(console: Console, context: ModelContext) {
        guard let running = console.runningEntry else { return }
        running.end = Date()
        console.lastActivityAt = Date()
        try? context.save()
    }

    func totalSeconds(for console: Console) -> TimeInterval {
        var total: TimeInterval = 0
        for t in console.timeEntries {
            let end = t.end ?? Date()
            total += end.timeIntervalSince(t.start)
        }
        return total
    }
}

