//
//  UIKitHelpers.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
import UIKit

extension UIApplication {
    var topMost: UIViewController? {
        guard
            let windowScene = connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first,
            let root = windowScene.keyWindow?.rootViewController
        else { return nil }

        var top = root
        while let presented = top.presentedViewController { top = presented }
        return top
    }
}

private extension UIWindowScene {
    var keyWindow: UIWindow? { windows.first { $0.isKeyWindow } }
}

