import SwiftUI
import AVFoundation
import PixloCapture

struct ContentView: View {

    @StateObject private var viewModel = CaptureViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .waitingForPermission:
                ProgressView("Requesting camera access…")
            case .permissionDenied:
                Text("Camera access denied.\nEnable it in System Settings > Privacy & Security > Camera.")
                    .multilineTextAlignment(.center)
                    .padding()
            case .noCamera:
                Text("No camera found on this device.")
                    .padding()
            case .error(let message):
                Text("Capture error: \(message)")
                    .padding()
            case .running(let session):
                CameraPreviewView(session: session)
            }
        }
        .frame(width: 640, height: 480)
        .task { await viewModel.start() }
        .onDisappear { viewModel.stop() }
    }
}

// MARK: - View model

@MainActor
final class CaptureViewModel: ObservableObject {

    enum State {
        case waitingForPermission
        case permissionDenied
        case noCamera
        case error(String)
        case running(AVCaptureSession)
    }

    @Published var state: State = .waitingForPermission

    private let captureManager = CaptureManager()
    private var hasStarted = false

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true

        let granted = await CapturePermission.requestCameraAccess()
        guard granted else {
            state = .permissionDenied
            return
        }

        guard let device = AVCaptureDevice.default(for: .video) else {
            state = .noCamera
            return
        }

        do {
            try captureManager.configure(device: device)
            state = .running(captureManager.captureSession)
            captureManager.start()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func stop() {
        captureManager.stop()
    }
}
