// PixloVCExtension.swift — Camera Extension entry point.
//
// Starts the CoreMediaIO extension service and registers the virtual camera device.
// RunLoop.main.run() keeps the process alive so the OS can dispatch client connections.

import CoreMediaIO
import Foundation

@main
enum PixloVCExtension {
    static func main() {
        let providerSource = VirtualCameraProvider()
        let provider = CMIOExtensionProvider(source: providerSource, clientQueue: nil)
        try? provider.addDevice(providerSource.cameraDevice)
        CMIOExtensionProvider.startService(provider: provider)
        RunLoop.main.run()
    }
}
