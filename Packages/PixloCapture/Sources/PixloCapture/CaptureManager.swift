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
    private let outputQueue = DispatchQueue(
        label: "vc.pixlo.capture.output",
        qos: .userInteractive
    )

    public override init() {
        super.init()
    }

    // MARK: - Configuration

    /// Configures the session with the given `AVCaptureDevice`.
    /// Call once before `start()`. Throws `CaptureError` on failure.
    public func configure(device: AVCaptureDevice) throws {
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
    }

    // MARK: - Lifecycle

    /// Starts the capture session on a background thread.
    public func start() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInteractive).async {
            self.session.startRunning()
        }
    }

    /// Stops the capture session.
    public func stop() {
        guard session.isRunning else { return }
        session.stopRunning()
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

public enum CaptureError: Error {
    case cannotAddInput
    case cannotAddOutput
    case noDefaultCamera
}
