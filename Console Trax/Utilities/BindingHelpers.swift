//
//  BindingHelpers.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
import SwiftUI

/// Promote an Optional binding to a non-optional one by providing a default value.
public func bind<T>(_ source: Binding<T?>, default defaultValue: @autoclosure @escaping () -> T) -> Binding<T> {
    Binding<T>(
        get: { source.wrappedValue ?? defaultValue() },
        set: { source.wrappedValue = $0 }
    )
}

