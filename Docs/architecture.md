# Architecture — Pixlo VC

> Status: **Draft** — details will be refined as implementation begins.

---

## System Context

Pixlo VC presents a virtual camera device to macOS so that any video-conferencing application (Zoom, Teams, Google Meet, etc.) can select it as a camera source. The virtual frames are produced by the Pixlo host app, which captures the real camera, applies transforms, and feeds the output through the Camera Extension.

```
┌─────────────────────────────────────────────────┐
│  macOS (user space)                             │
│                                                 │
│  ┌──────────────┐      Shared Settings          │
│  │  Host App    │◄──────────────────────────►  │
│  │  (SwiftUI)   │                  ┌───────────┐│
│  └──────┬───────┘                  │  Camera   ││
│         │ CMSampleBuffer           │ Extension ││
│         ▼                          │ (DAL/CMIODALPlugIn) ││
│  ┌──────────────┐   pixel buffer   └─────┬─────┘│
│  │  Capture     │──────────────────────► │      │
│  │  Pipeline    │                  ┌─────▼─────┐│
│  └──────────────┘                  │  Render   ││
│                                    │  Pipeline ││
│                                    └───────────┘│
└─────────────────────────────────────────────────┘
         ▲                                 │
         │ AVCaptureDevice                 │ Virtual camera frames
         │ (physical camera)               ▼
                                   Video-conferencing app
```

---

## Components

### Host App (`Apps/PixloVC`)

- **Technology**: SwiftUI + AppKit, macOS 14+
- **Responsibilities**:
  - Manage camera capture session (`AVCaptureSession`)
  - Present controls: crop/zoom, mirror, frame rate, filter selector
  - Write shared settings to App Group container
  - Install / activate the Camera Extension on first launch
- **Key files** (to be created):
  - `PixloVCApp.swift` — app entry point
  - `ContentView.swift` — main controls UI
  - `CaptureManager.swift` — `AVCaptureSession` lifecycle

### Camera Extension (`Apps/PixloVCExtension`)

- **Technology**: System Extension, CoreMediaIO Camera Extension API (`CMIOExtensionProvider` / `CMIOExtensionDevice` — available macOS 12.3+)
- **Responsibilities**:
  - Register as a virtual CMIODevice
  - Read latest frame from shared `IOSurface` (written by host app)
  - Enqueue frames into the CMIOStream on a timer
- **Key files** (to be created):
  - `main.swift` — extension entry point
  - `VirtualCameraProvider.swift` — `CMIOExtensionProvider` subclass
  - `VirtualCameraDevice.swift` — `CMIOExtensionDevice` subclass

### Capture Pipeline (`Packages/PixloCapture`)

- **Responsibilities**:
  - Wrap `AVCaptureSession` and `AVCaptureVideoDataOutput`
  - Emit `CVPixelBuffer` frames to consumers
  - Handle permission requests
- **v1 constraint**: one physical camera at a time. Multiple simultaneous physical cameras are out of scope for v1.

### Render Pipeline (`Packages/PixloRender`)

- **Responsibilities**:
  - Apply crop/zoom (Metal compute or `CIFilter`)
  - Apply mirror transform
  - Apply lightweight filters (brightness, contrast, grayscale)
  - Output a `CVPixelBuffer` ready for the extension
- **Open decision**: Metal vs. Core Image vs. Vision for each transform stage.

### Shared Settings / State (`Packages/PixloShared`)

- **Responsibilities**:
  - Define `CameraSettings` value type (codable)
  - Read/write settings via `UserDefaults(suiteName:)` in an App Group
  - Provide a Combine publisher so both app and extension react to changes
- **Open decision**: App Group identifier (requires provisioning profile decision).

---

## Data Flow (steady state)

```
Physical Camera
    │  AVCaptureVideoDataOutput (CVPixelBuffer)
    ▼
Capture Pipeline
    │  CVPixelBuffer (raw)
    ▼
Render Pipeline  ◄── CameraSettings (via PixloShared)
    │  CVPixelBuffer (processed)
    ▼
IOSurface (shared memory, latest-frame-wins)
    │
    ▼
Camera Extension  →  CMIOStream  →  Video app
```

---

## Build & Signing Requirements

- Camera Extension requires code signing (Apple Development or Developer ID).
- Host app needs `com.apple.developer.system-extension.install` entitlement.
- Both host app and extension need `com.apple.security.application-groups` with the shared App Group ID.
- Extension `.appex` embedded at `Contents/Library/SystemExtensions/` in host app bundle.
- Hardened Runtime enabled (required for notarization in Phase 5).
- Host app is **not sandboxed** (simplifies System Extension installation).

---

## Phased Milestones

| Phase | Goal |
|---|---|
| **0 — Skeleton** | Repository structure, docs, build system, no logic |
| **1 — Capture** | Physical camera capture, preview in host app |
| **2 — Extension** | Virtual camera visible to system, passes raw frames |
| **3 — Transforms** | Crop/zoom, mirror, frame rate control |
| **4 — Filters** | Brightness, contrast, grayscale, blur |
| **5 — Polish** | Onboarding, settings persistence, menubar icon |

---

## Resolved Decisions

1. **IPC mechanism (P03):** `IOSurface` shared memory. Host writes frames to a shared IOSurface; extension reads on a timer. Latest-frame-wins — no queue, no ring buffer. IOSurfaceID passed via App Group UserDefaults.
2. **Minimum macOS version (P03):** 14.0 (Sonoma). CMIOExtensionProvider available since 12.3; 14.0 required for Swift concurrency and SwiftUI features.
3. **App Group ID (P03):** `group.vc.pixlo.app` (placeholder — update when team ID is confirmed).
4. **Extension bundle ID (P03):** `vc.pixlo.PixloVC.Extension`.

## Open Decisions

1. Metal pipeline vs. Core Image for render transforms (Phase 3).
2. Distribution channel: direct download vs. Mac App Store (affects entitlements; Phase 5).
