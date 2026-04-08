// ExtensionInstaller.swift — Manages Camera Extension lifecycle.
//
// Wraps OSSystemExtensionManager to activate and deactivate the Pixlo VC
// Camera Extension. The host app owns this lifecycle; the extension itself
// has no activation logic.

import Combine
import Foundation
import PixloShared
import SystemExtensions

enum ExtensionStatus: Equatable {
    case unknown
    case installing
    case awaitingApproval
    case active
    case failed(String)
}

@MainActor
final class ExtensionInstaller: NSObject, ObservableObject {

    static let extensionBundleID = AppConstants.extensionBundleID

    @Published private(set) var status: ExtensionStatus = .unknown

    func install() {
        status = .installing
        let request = OSSystemExtensionRequest.activationRequest(
            forExtensionWithIdentifier: Self.extensionBundleID,
            queue: .main
        )
        request.delegate = self
        OSSystemExtensionManager.shared.submitRequest(request)
    }

    func uninstall() {
        let request = OSSystemExtensionRequest.deactivationRequest(
            forExtensionWithIdentifier: Self.extensionBundleID,
            queue: .main
        )
        request.delegate = self
        OSSystemExtensionManager.shared.submitRequest(request)
    }
}

// MARK: OSSystemExtensionRequestDelegate

extension ExtensionInstaller: OSSystemExtensionRequestDelegate {

    nonisolated func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension ext: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        .replace
    }

    nonisolated func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        Task { @MainActor in
            self.status = .awaitingApproval
        }
    }

    nonisolated func request(
        _ request: OSSystemExtensionRequest,
        didFinishWithResult result: OSSystemExtensionRequest.Result
    ) {
        Task { @MainActor in
            self.status = .active
        }
    }

    nonisolated func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        Task { @MainActor in
            self.status = .failed(error.localizedDescription)
        }
    }
}
