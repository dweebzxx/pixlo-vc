// VirtualCameraStream.swift — CMIOExtensionStreamSource implementation.
//
// Emits synthetic solid-color frames at 30 fps.
// No physical camera or IOSurface is involved in this milestone — the output
// is a deterministic test pattern that validates extension registration and
// frame delivery without requiring live passthrough infrastructure.

import CoreMedia
import CoreMediaIO
import CoreVideo
import Foundation

final class VirtualCameraStream: NSObject, CMIOExtensionStreamSource {

    // Fixed UUID — stable across launches so clients can reconnect.
    private static let streamID = UUID(uuidString: "72DE0A84-4028-4ADE-B7A2-CC8B37C6D0EA")!

    static let width: Int32 = 1280
    static let height: Int32 = 720
    static let frameRate: Int32 = 30

    private(set) var extensionStream: CMIOExtensionStream!
    private var timer: DispatchSourceTimer?
    private var activeFormatIndex: Int = 0

    private lazy var streamFormat: CMIOExtensionStreamFormat = {
        var formatDesc: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: kCVPixelFormatType_32BGRA,
            width: Self.width,
            height: Self.height,
            extensions: nil,
            formatDescriptionOut: &formatDesc
        )
        // minFrameDuration = 1/30 s (fastest), maxFrameDuration = 1/1 s (slowest)
        return CMIOExtensionStreamFormat(
            formatDescription: formatDesc!,
            maxFrameDuration: CMTime(value: 1, timescale: 1),
            minFrameDuration: CMTime(value: 1, timescale: Self.frameRate),
            validFrameDurations: nil
        )
    }()

    override init() {
        super.init()
        extensionStream = CMIOExtensionStream(
            localizedName: "Pixlo VC Video",
            streamID: Self.streamID,
            direction: .source,
            clockType: .hostTime,
            source: self
        )
    }

    // MARK: CMIOExtensionStreamSource

    var formats: [CMIOExtensionStreamFormat] {
        [streamFormat]
    }

    var availableProperties: Set<CMIOExtensionProperty> {
        [.streamActiveFormatIndex, .streamFrameDuration]
    }

    func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
        let result = CMIOExtensionStreamProperties(dictionary: [:])
        if properties.contains(.streamActiveFormatIndex) {
            result.activeFormatIndex = activeFormatIndex
        }
        if properties.contains(.streamFrameDuration) {
            result.frameDuration = CMTime(value: 1, timescale: Self.frameRate)
        }
        return result
    }

    func setStreamProperties(_ streamProperties: CMIOExtensionStreamProperties) throws {
        if let index = streamProperties.activeFormatIndex {
            activeFormatIndex = index
        }
    }

    func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool {
        true
    }

    func startStream() throws {
        let queue = DispatchQueue(label: "vc.pixlo.extension.stream", qos: .userInteractive)
        let source = DispatchSource.makeTimerSource(queue: queue)
        source.schedule(deadline: .now(), repeating: 1.0 / Double(Self.frameRate), leeway: .milliseconds(2))
        source.setEventHandler { [weak self] in
            self?.emitFrame()
        }
        source.resume()
        timer = source
    }

    func stopStream() throws {
        timer?.cancel()
        timer = nil
    }

    // MARK: Private

    private func emitFrame() {
        guard let sampleBuffer = makeSyntheticSampleBuffer() else { return }
        let now = mach_absolute_time()
        extensionStream.send(
            sampleBuffer,
            discontinuity: [],
            hostTimeInNanoseconds: machToNanoseconds(now)
        )
    }

    private func makeSyntheticSampleBuffer() -> CMSampleBuffer? {
        // Allocate a pixel buffer and fill with a solid mid-gray test pattern.
        var pixelBuffer: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferWidthKey as String: Self.width,
            kCVPixelBufferHeightKey as String: Self.height,
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(Self.width),
            Int(Self.height),
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        if let base = CVPixelBufferGetBaseAddress(buffer) {
            let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
            // 0x7F fills B=0x7F G=0x7F R=0x7F A=0x7F — a recognisable mid-gray test pattern.
            memset(base, 0x7F, bytesPerRow * Int(Self.height))
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])

        // Create a format description from the pixel buffer.
        var formatDesc: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: buffer,
            formatDescriptionOut: &formatDesc
        )
        guard let formatDescription = formatDesc else { return nil }

        // Build timing for the current frame.
        let now = CMClockGetTime(CMClockGetHostTimeClock())
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: Self.frameRate),
            presentationTimeStamp: now,
            decodeTimeStamp: .invalid
        )

        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: buffer,
            formatDescription: formatDescription,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        return sampleBuffer
    }

    private func machToNanoseconds(_ machTime: UInt64) -> UInt64 {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        return machTime * UInt64(timebase.numer) / UInt64(timebase.denom)
    }
}
