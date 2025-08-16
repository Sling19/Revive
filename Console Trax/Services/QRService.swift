//
//  QRService.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
// =====================================================
// Services/QRService.swift
// =====================================================
import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRService {
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    func makeQRCode(from string: String, scale: CGFloat = 8) -> UIImage? {
        filter.message = Data(string.utf8)
        guard let output = filter.outputImage else { return nil }
        let transformed = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        if let cg = context.createCGImage(transformed, from: transformed.extent) {
            return UIImage(cgImage: cg)
        }
        return nil
    }
}

