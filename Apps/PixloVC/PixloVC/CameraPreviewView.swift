import SwiftUI
import AVFoundation

/// SwiftUI wrapper around `AVCaptureVideoPreviewLayer` for live camera preview.
struct CameraPreviewView: NSViewRepresentable {

    let session: AVCaptureSession

    func makeNSView(context: Context) -> PreviewNSView {
        let view = PreviewNSView()
        view.session = session
        return view
    }

    func updateNSView(_ nsView: PreviewNSView, context: Context) {
        nsView.session = session
    }
}

// MARK: -

final class PreviewNSView: NSView {

    var session: AVCaptureSession? {
        didSet { previewLayer.session = session }
    }

    private let previewLayer = AVCaptureVideoPreviewLayer()

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        previewLayer.videoGravity = .resizeAspect
        layer?.addSublayer(previewLayer)
    }

    override func layout() {
        super.layout()
        previewLayer.frame = bounds
    }
}
