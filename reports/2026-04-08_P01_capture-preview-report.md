# P01 — Capture & Preview Report

**Date:** 2026-04-08  
**Branch:** `feat/p01-capture-preview`  
**Prompt ID:** P01

---

## 1. Objective Completed

Created the minimal macOS host app and `PixloCapture` Swift package. The host app displays a live camera preview via `AVCaptureVideoPreviewLayer`. `CaptureManager` wraps `AVCaptureSession` and emits raw `CVPixelBuffer` frames via a Combine `PassthroughSubject`. Camera permission is handled at runtime with a graceful error UI for denied/no-camera states.

---

## 2. Repo State Inspected

- **Branch at start:** `main` (ahead of origin by 1)
- **Untracked:** `reports/2026-04-08_P00_repo-intake-audit.md`
- **Pre-existing structure:** `Apps/README.md`, `Packages/README.md` (placeholders only)
- **Docs read:** `CLAUDE.md`, `README.md`, `Docs/architecture.md`, `Docs/roadmap.md`, `Docs/qa-matrix.md`, `Scripts/bootstrap.sh`
- **No Xcode project existed** — created from scratch as required by P01

---

## 3. Files Created

### Swift Package

| File | Purpose |
|---|---|
| `Packages/PixloCapture/Package.swift` | swift-tools-version 5.10, macOS 14+, library target |
| `Packages/PixloCapture/Sources/PixloCapture/CaptureManager.swift` | AVCaptureSession wrapper; emits CVPixelBuffer via Combine |
| `Packages/PixloCapture/Sources/PixloCapture/CapturePermission.swift` | Async camera TCC permission helper |

### Host App Sources

| File | Purpose |
|---|---|
| `Apps/PixloVC/PixloVC/PixloVCApp.swift` | `@main` SwiftUI entry point |
| `Apps/PixloVC/PixloVC/ContentView.swift` | State-driven UI; `CaptureViewModel` handles permission + session |
| `Apps/PixloVC/PixloVC/CameraPreviewView.swift` | `NSViewRepresentable` wrapping `AVCaptureVideoPreviewLayer` |
| `Apps/PixloVC/PixloVC/Info.plist` | `NSCameraUsageDescription` + standard bundle keys |

### Xcode Project & Workspace

| File | Purpose |
|---|---|
| `Apps/PixloVC/PixloVC.xcodeproj/project.pbxproj` | Hand-authored pbxproj; links PixloCapture via `XCLocalSwiftPackageReference` |
| `Apps/PixloVC/PixloVC.xcodeproj/project.xcworkspace/contents.xcworkspacedata` | Inner workspace self-reference |
| `Apps/PixloVC/PixloVC.xcodeproj/xcshareddata/xcschemes/PixloVC.xcscheme` | Shared scheme for `xcodebuild` and Xcode |
| `Pixlo.xcworkspace/contents.xcworkspacedata` | Root workspace; references app project + PixloCapture package |

---

## 4. Files Updated

None — no existing source files were modified. The P00 intake report (`reports/2026-04-08_P00_repo-intake-audit.md`) was staged as part of this commit (previously untracked).

---

## 5. Architecture Choices Made

| Choice | Decision | Rationale |
|---|---|---|
| Frame emission pattern | Combine `PassthroughSubject<CVPixelBuffer, Never>` | Aligns with roadmap spec; ready for P02 IPC wiring without over-engineering |
| Preview mechanism | `AVCaptureVideoPreviewLayer` via `NSViewRepresentable` | Lowest-overhead preview; Metal not needed until P03 render pipeline |
| ViewModel state | `enum State` with five cases | Makes each error path explicit and testable; avoids boolean flags |
| Package link | `XCLocalSwiftPackageReference` in pbxproj | Standard Xcode 14+ local package mechanism; no third-party tooling |
| Code signing | Unsigned (`CODE_SIGNING_ALLOWED=NO` at build time) | No Developer Account required for P01 build validation; signing deferred to P05 |
| No sandboxing | Entitlements file omitted | Sandboxed camera entitlement requires signing; deferred to P05 |
| No unit tests | Skipped | P01 prompt says "minimum supporting files"; QA matrix marks tests 🔲 for P01 |

---

## 6. Validation Commands Run

```
# Environment check
bash Scripts/bootstrap.sh

# Package standalone build
cd Packages/PixloCapture && swift build

# Workspace build (scheme PixloVC)
xcodebuild -workspace Pixlo.xcworkspace \
  -scheme PixloVC \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build
```

---

## 7. Build Status

| Step | Result |
|---|---|
| `bootstrap.sh` | ✅ macOS 26.3.1 ≥ 14, Xcode 26.4 ≥ 16 (two expected signing warnings) |
| `swift build` (PixloCapture) | ✅ Build complete, 0 warnings |
| `xcodebuild` (PixloVC app) | ✅ **BUILD SUCCEEDED**, 0 warnings, 0 errors |

---

## 8. Known Issues and Limitations

1. **Camera permission requires running app** — TCC prompt only appears when the app launches on a real machine. CI/headless builds skip this naturally.
2. **No code signing** — app cannot be distributed or tested on a device without signing. Deferred to P05.
3. **No unit tests** — `CaptureManager` lifecycle (start/stop state transitions) and `CapturePermission` are untested. P01 QA matrix items CAP-02/CAP-03/CAP-04 remain 🔲.
4. **No asset catalog** — `AppIcon` and `AccentColor` references in build settings are harmless (no `GENERATE_INFOPLIST_FILE`), but Xcode will show missing asset warnings if opened interactively. Will be addressed in P05 polish.
5. **`xcodebuild -scheme` with `-project` fails** — must use `-workspace Pixlo.xcworkspace` to resolve the local package. Documented for P02 handoff.
6. **PixloCapture publisher not consumed in UI** — `pixelBufferPublisher` is wired but has no subscriber in P01. The preview layer renders independently. Publisher is ready for P02.

---

## 9. Readiness Verdict

**READY FOR P02**

### Scope Codex should handle next

P02 — Virtual Camera Extension:
- Add `PixloVCExtension` system extension target to the Xcode project
- Implement `CMIOExtensionProvider` / `CMIOExtensionDevice` / `CMIOExtensionStream`
- Wire IPC from host app → extension (XPC or IOSurface; decision to be made in P02)
- Subscribe to `CaptureManager.pixelBufferPublisher` in the host app and forward buffers to the extension
- Add host-app UI to install/activate/deactivate the extension
- Virtual camera must be selectable in FaceTime or Zoom

### P02 Validation Checklist

- [ ] `xcodebuild -workspace Pixlo.xcworkspace -scheme PixloVCExtension` builds without errors
- [ ] Signed build registers virtual device: appears in `system_profiler SPCameraDataType`
- [ ] FaceTime or Zoom can select "Pixlo VC" as camera source
- [ ] Raw frames from physical camera visible in the consuming app
- [ ] No frame drops > 1 % at 30 fps over 60 s (EXT-04)
- [ ] Stopping the host app does not leave a zombie extension process (EXT-02)
