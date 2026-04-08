// VirtualCameraProvider.swift — CMIOExtensionProviderSource implementation.
//
// Creates and exposes the single virtual camera device to the system.

import CoreMediaIO
import Foundation

final class VirtualCameraProvider: NSObject, CMIOExtensionProviderSource {

    private let device: VirtualCameraDevice

    override init() {
        device = VirtualCameraDevice()
        super.init()
    }

    /// The CMIOExtensionDevice registered with the provider.
    var cameraDevice: CMIOExtensionDevice {
        device.extensionDevice
    }

    // MARK: CMIOExtensionProviderSource

    var availableProperties: Set<CMIOExtensionProperty> {
        [.providerManufacturer]
    }

    func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
        let result = CMIOExtensionProviderProperties(dictionary: [:])
        if properties.contains(.providerManufacturer) {
            result.manufacturer = "Pixlo"
        }
        return result
    }

    func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {}

    func connect(to client: CMIOExtensionClient) throws {}

    func disconnect(from client: CMIOExtensionClient) {}
}
