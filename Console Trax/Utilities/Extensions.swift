//
//  Extensions.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
// =====================================================
// Utilities/Extensions.swift
// =====================================================
import Foundation

extension Date {
    var yyyyMMddHHmm: String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmm"
        return f.string(from: self)
    }
}

extension TimeInterval {
    var asHMS: String {
        let s = Int(self)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return String(format: "%02d:%02d:%02d", h, m, sec)
    }
}

extension Decimal {
    var currency: String {
        let num = NSDecimalNumber(decimal: self).doubleValue
        return num.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}
