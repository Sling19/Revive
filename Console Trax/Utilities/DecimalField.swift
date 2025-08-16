//
//  DecimalField.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
import SwiftUI

public struct DecimalField: View {
    public var title: String
    @Binding public var value: Decimal?
    @State private var text: String = ""

    public init(title: String, value: Binding<Decimal?>) {
        self.title = title
        self._value = value
        if let v = value.wrappedValue {
            _text = State(initialValue: "\(NSDecimalNumber(decimal: v))")
        }
    }

    public var body: some View {
        TextField(title, text: $text)
            .keyboardType(.decimalPad)
            .onChange(of: text) { _, new in
                self.value = Decimal(string: new)
            }
    }
}

