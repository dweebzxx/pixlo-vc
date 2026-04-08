# Packages

This directory will contain reusable Swift packages shared between the host app and the Camera Extension:

| Package | Description |
|---|---|
| `PixloCapture` | `AVCaptureSession` management and `CVPixelBuffer` publisher |
| `PixloRender` | Crop/zoom, mirror, frame-rate control, and lightweight filters |
| `PixloShared` | `CameraSettings` model, App Group persistence, Combine publishers |

Each package will be a local Swift Package Manager package added to the workspace.

> **Status**: Placeholder — packages will be created in Phases 1–3.
