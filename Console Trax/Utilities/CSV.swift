//
//  CSV.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
// =====================================================
// Utilities/CSV.swift
// =====================================================
import Foundation

enum CSV {
    static func make(rows: [[String]]) -> String {
        rows.map { $0.map { escape($0) }.joined(separator: ",") }
            .joined(separator: "\n")
    }
    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\n") || field.contains("\"") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }
}
