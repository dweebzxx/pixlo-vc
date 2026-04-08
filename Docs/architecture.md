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
  - Receive processed pixel buffers from the host (via IPC / shared memory — decision pending)
  - Enqueue frames into the CMIOStream
- **Key files** (to be created):
  - `main.swift` — extension entry point
  - `VirtualCameraProvider.swift` — `CMIOExtensionProvider` subclass
  - `VirtualCameraDevice.swift` — `CMIOExtensionDevice` subclass

### Capture Pipeline (`Packages/PixloCapture`)

- **Responsibilities**:
  - Wrap `AVCaptureSession` and `AVCaptureVideoDataOutput`
  - Emit `CVPixelBuffer` frames to consumers
  - Handle permission requests
- **Open decision**: whether to support multiple simultaneous physical cameras.

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
IPC / Shared Memory  (mechanism TBD)
    │
    ▼
Camera Extension  →  CMIOStream  →  Video app
```

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

## Open Decisions

1. IPC mechanism between host app and extension (XPC vs. shared memory via `IOSurface`).
2. Metal pipeline vs. Core Image for render transforms.
3. App Group identifier — depends on team ID and provisioning.
4. Minimum macOS version (14.0 Sonoma or 15.0 Sequoia).
5. Distribution channel: direct download vs. Mac App Store (affects entitlements).
