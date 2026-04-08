// AppConstants.swift — Shared constants for Pixlo VC host app and Camera Extension.

public enum AppConstants {
    /// App Group identifier shared by the host app and the Camera Extension.
    /// Must match the App Group provisioned in the Apple Developer portal.
    public static let appGroupID = "group.vc.pixlo.app"

    /// Bundle identifier of the Camera Extension.
    /// Must match the extension target's PRODUCT_BUNDLE_IDENTIFIER.
    public static let extensionBundleID = "vc.pixlo.PixloVC.Extension"
}
