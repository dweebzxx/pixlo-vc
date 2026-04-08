import SwiftUI
import AVFoundation
import PixloCapture

struct ContentView: View {

    @StateObject private var viewModel = CaptureViewModel()
    @StateObject private var installer = ExtensionInstaller()

    var body: some View {
        VStack(spacing: 0) {
            cameraView
            extensionStatusBar
        }
        .frame(width: 640, height: 510)
        .task { await viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var cameraView: some View {
        Group {
            switch viewModel.state {
            case .waitingForPermission:
                ProgressView("Requesting camera access…")
                    .frame(height: 480)
            case .permissionDenied:
                Text("Camera access denied.\nEnable it in System Settings > Privacy & Security > Camera.")
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(height: 480)
            case .noCamera:
                Text("No camera found on this device.")
                    .padding()
                    .frame(height: 480)
            case .error(let message):
                Text("Capture error: \(message)")
                    .padding()
                    .frame(height: 480)
            case .running(let session):
                CameraPreviewView(session: session)
                    .frame(height: 480)
            }
        }
    }

    private var extensionStatusBar: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            extensionButton
        }
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(.bar)
    }

    @ViewBuilder
    private var extensionButton: some View {
        switch installer.status {
        case .unknown, .failed:
            Button("Install Virtual Camera") { installer.install() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        case .installing, .awaitingApproval:
            ProgressView()
                .controlSize(.small)
        case .active:
            Button("Uninstall") { installer.uninstall() }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }

    private var statusColor: Color {
        switch installer.status {
        case .active: return .green
        case .failed: return .red
        case .awaitingApproval: return .orange
        default: return .secondary
        }
    }

    private var statusLabel: String {
        switch installer.status {
        case .unknown: return "Virtual camera: not installed"
        case .installing: return "Installing…"
        case .awaitingApproval: return "Waiting for approval in System Settings"
        case .active: return "Virtual camera: active"
        case .failed(let msg): return "Error: \(msg)"
        }
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
