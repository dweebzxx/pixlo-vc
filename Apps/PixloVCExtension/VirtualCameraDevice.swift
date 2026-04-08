// VirtualCameraDevice.swift — CMIOExtensionDeviceSource implementation.
//
// Represents the "Pixlo VC" virtual camera device visible in the system camera list.

import CoreMediaIO
import Foundation

final class VirtualCameraDevice: NSObject, CMIOExtensionDeviceSource {

    // Fixed UUID — stable across launches so the OS treats this as the same device.
    private static let deviceID = UUID(uuidString: "CD3F2FA4-D4B3-4B61-9086-F6D89BC5F42E")!

    private(set) var extensionDevice: CMIOExtensionDevice!
    private let stream: VirtualCameraStream

    override init() {
        stream = VirtualCameraStream()
        super.init()
        extensionDevice = CMIOExtensionDevice(
            localizedName: "Pixlo VC",
            deviceID: Self.deviceID,
            legacyDeviceID: nil,
            source: self
        )
        try? extensionDevice.addStream(stream.extensionStream)
    }

    // MARK: CMIOExtensionDeviceSource

    var availableProperties: Set<CMIOExtensionProperty> {
        [.deviceModel]
    }

    func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
        let result = CMIOExtensionDeviceProperties(dictionary: [:])
        if properties.contains(.deviceModel) {
            result.model = "Pixlo VC Virtual Camera"
        }
        return result
    }

    func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {}
}
