import AVFoundation
import Combine

/// Wraps `AVCaptureSession` and emits raw `CVPixelBuffer` frames via a Combine publisher.
public final class CaptureManager: NSObject {

    // MARK: - Public interface

    /// Emits raw pixel buffers from the capture output queue.
    /// Downstream subscribers are responsible for thread-hopping if needed.
    public let pixelBufferPublisher = PassthroughSubject<CVPixelBuffer, Never>()

    /// The underlying capture session; pass to `AVCaptureVideoPreviewLayer` for live preview.
    public var captureSession: AVCaptureSession { session }

    // MARK: - Private

    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(
        label: "vc.pixlo.capture.session",
        qos: .userInitiated
    )
    private let outputQueue = DispatchQueue(
        label: "vc.pixlo.capture.output",
        qos: .userInteractive
    )
    private var isConfigured = false

    public override init() {
        super.init()
    }

    // MARK: - Configuration

    /// Configures the session with the given `AVCaptureDevice`.
    /// Call once before `start()`. Throws `CaptureError` on failure.
    public func configure(device: AVCaptureDevice) throws {
        guard !isConfigured else { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw CaptureError.cannotAddInput
        }
        session.addInput(input)

        videoOutput.setSampleBufferDelegate(self, queue: outputQueue)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true

        guard session.canAddOutput(videoOutput) else {
            throw CaptureError.cannotAddOutput
        }
        session.addOutput(videoOutput)
        isConfigured = true
    }

    // MARK: - Lifecycle

    /// Starts the capture session on a background thread.
    public func start() {
        sessionQueue.async {
            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    /// Stops the capture session.
    public func stop() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CaptureManager: AVCaptureVideoDataOutputSampleBufferDelegate {

    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        pixelBufferPublisher.send(pixelBuffer)
    }
}

// MARK: - Errors

public enum CaptureError: LocalizedError {
    case cannotAddInput
    case cannotAddOutput
    case noDefaultCamera

    public var errorDescription: String? {
        switch self {
        case .cannotAddInput:
            return "Unable to add the selected camera as a capture input."
        case .cannotAddOutput:
            return "Unable to configure the capture output for camera frames."
        case .noDefaultCamera:
            return "No usable camera is available."
        }
    }
}
