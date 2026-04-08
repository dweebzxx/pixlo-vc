import AVFoundation

/// Utility for requesting and checking camera authorisation.
public enum CapturePermission {

    /// Returns `true` if camera access is currently authorised, requesting it if not yet determined.
    public static func requestCameraAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}
