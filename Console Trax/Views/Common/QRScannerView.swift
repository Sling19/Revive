//
//  QRScannerView.swift
//  Console Trax
//
//  Created by Kyle on 8/16/25.
//
// ================= Views/Common/QRScannerView.swift =================
import SwiftUI
import VisionKit

struct QRScannerView: UIViewControllerRepresentable {
    var onURLDetected: (URL) -> Void
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(recognizedDataTypes: [.barcode(symbologies: [.qr])], qualityLevel: .accurate, recognizesMultipleItems: false, isHighFrameRateTrackingEnabled: true, isPinchToZoomEnabled: true)
        vc.delegate = context.coordinator
        try? vc.startScanning()
        return vc
    }
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}
    func makeCoordinator() -> Coord { Coord(onURLDetected: onURLDetected) }
    final class Coord: NSObject, DataScannerViewControllerDelegate {
        var onURLDetected: (URL) -> Void
        init(onURLDetected: @escaping (URL) -> Void) { self.onURLDetected = onURLDetected }
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            if case .barcode(let b) = item, let payload = b.payloadStringValue, let url = URL(string: payload) { onURLDetected(url) }
        }
    }
}

