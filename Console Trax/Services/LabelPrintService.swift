//
//  LabelPrintService.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
import UIKit

enum LabelPrintService {

    /// 2" x 1" style label (defaults to 600x300 px @ ~300 dpi).
    static func labelImage(for console: Console, dpi300: Bool = true) -> UIImage {
        let size = dpi300 ? CGSize(width: 600, height: 300) : CGSize(width: 406, height: 203) // ~203 dpi 2x1"
        let qrSide = min(size.height - 24, 260)
        let qrInset: CGFloat = 12

        // Make QR
        let url = "xrt://console/\(console.id.uuidString)"
        let qr = QRService().makeQRCode(from: url) ?? UIImage()

        let renderer = UIGraphicsImageRenderer(size: size, format: UIGraphicsImageRendererFormat.default())
        return renderer.image { ctx in
            // Background white (most thermal printers prefer solid white)
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // Draw QR left
            let qrRect = CGRect(x: qrInset, y: (size.height - qrSide) / 2, width: qrSide, height: qrSide)
            qr.draw(in: qrRect)

            // Text on the right
            let rightX = qrRect.maxX + 16
            let textWidth = size.width - rightX - 14

            let title = console.title.isEmpty ? "Console" : console.title
            let idShort = console.id.uuidString.prefix(8)
            let status = console.status.rawValue.capitalized

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .semibold),
                .foregroundColor: UIColor.black
            ]
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .regular),
                .foregroundColor: UIColor.black
            ]

            let titleRect = CGRect(x: rightX, y: qrRect.minY, width: textWidth, height: 80)
            NSString(string: title).draw(in: titleRect, withAttributes: titleAttrs)

            let meta = "ID: \(idShort)   •   \(status)"
            let metaRect = CGRect(x: rightX, y: titleRect.maxY + 6, width: textWidth, height: 28)
            NSString(string: meta).draw(in: metaRect, withAttributes: subAttrs)

            if let tag = console.tags.first {
                let tagRect = CGRect(x: rightX, y: metaRect.maxY + 4, width: textWidth, height: 24)
                NSString(string: "#\(tag)").draw(in: tagRect, withAttributes: subAttrs)
            }
        }
    }

    /// System share sheet (Save to Files, AirDrop, vendor apps, **Print** option included).
    static func shareConsoleLabel(console: Console) {
        let image = labelImage(for: console)
        let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        UIApplication.shared.topMost?.present(av, animated: true)
    }

    /// Directly invoke AirPrint UI with the label image.
    static func printConsoleLabel(console: Console) {
        let image = labelImage(for: console)
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "Console Label"
        printInfo.outputType = .photo // best for bitmaps on thermal printers that support AirPrint
        let controller = UIPrintInteractionController.shared
        controller.printInfo = printInfo
        controller.printingItem = image
        controller.showsNumberOfCopies = false
        controller.present(animated: true, completionHandler: nil)
    }
}

