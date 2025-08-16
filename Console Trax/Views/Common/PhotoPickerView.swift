//
//  PhotoPickerView.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
// ================= Views/Common/PhotoPickerView.swift =================
import SwiftUI

extension Binding where Value == String? {
    func string() -> Binding<String> { Binding<String>(get: { self.wrappedValue ?? "" }, set: { self.wrappedValue = $0.isEmpty ? nil : $0 }) }
}

extension Binding where Value == URL? {
    func string() -> Binding<String> { Binding<String>(get: { self.wrappedValue?.absoluteString ?? "" }, set: { self.wrappedValue = $0.isEmpty ? nil : URL(string: $0) }) }
}

extension Binding where Value == Date? { init(_ source: Binding<Date?>, _ defaultDate: Date) { self.init(get: { source.wrappedValue ?? defaultDate }, set: { source.wrappedValue = $0 }) } }

