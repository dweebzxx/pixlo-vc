# P04 — Camera Extension Skeleton Report

**Date:** 2026-04-08
**Branch:** `feat/p04-extension-skeleton`
**Prompt ID:** P04

---

## 1. Objective Completed

Added a Camera Extension skeleton (Checkpoint A: synthetic frames) to the Pixlo VC workspace. The extension compiles, is embedded in the host app bundle at the correct location, and emits solid-color synthetic frames at 30 fps. Live passthrough (IOSurface) is deferred to P05 as specified.

---

## 2. Targets / Modules Created or Updated

| Item | Status | Notes |
|---|---|---|
| `Apps/PixloVCExtension/` | **Created** | System extension target with four Swift files |
| `Packages/PixloShared/` | **Created** | Minimal shared package; `AppConstants.swift` only |
| `Apps/PixloVC/PixloVC/ExtensionInstaller.swift` | **Created** | `OSSystemExtensionManager` wrapper |
| `Apps/PixloVC/PixloVC/PixloVC.entitlements` | **Created** | Host app entitlements |
| `Apps/PixloVC/PixloVC/ContentView.swift` | **Updated** | Added extension install/status bar |
| `Apps/PixloVC/PixloVC.xcodeproj/project.pbxproj` | **Updated** | Added extension target, PixloShared dep, CopyFiles phase |
| `Pixlo.xcworkspace/contents.xcworkspacedata` | **Updated** | Added PixloShared to workspace |
| `CLAUDE.md` | **Updated** | Current phase updated to P05 preparation |

### Extension source files

| File | Purpose |
|---|---|
| `PixloVCExtension.swift` | `@main` entry point; creates provider + device, starts service |
| `VirtualCameraProvider.swift` | `CMIOExtensionProviderSource`; creates and holds `VirtualCameraDevice` |
| `VirtualCameraDevice.swift` | `CMIOExtensionDeviceSource`; fixed UUID `CD3F2FA4-...`; holds `VirtualCameraStream` |
| `VirtualCameraStream.swift` | `CMIOExtensionStreamSource`; 1280×720 BGRA; 30 fps `DispatchSourceTimer`; solid-gray synthetic frames |
| `Info.plist` | `CMIOExtensionMachServiceName = vc.pixlo.PixloVC.Extension.mach`; `CFBundlePackageType = SYSX` |
| `PixloVCExtension.entitlements` | `com.apple.security.application-groups` |

---

## 3. Entitlements / Capabilities Added

| Target | Entitlement | Value |
|---|---|---|
| `PixloVC` (host) | `com.apple.developer.system-extension.install` | `true` |
| `PixloVC` (host) | `com.apple.security.application-groups` | `group.vc.pixlo.app` |
| `PixloVCExtension` | `com.apple.security.application-groups` | `group.vc.pixlo.app` |

Both targets have `ENABLE_HARDENED_RUNTIME = YES` and `DEVELOPMENT_TEAM = P4KPQ56YNX`.

---

## 4. Validation Commands Run

```bash
# Environment check
bash Scripts/bootstrap.sh

# Compilation-only build (both targets, unsigned)
xcodebuild -workspace Pixlo.xcworkspace \
  -scheme PixloVC \
  -configuration Debug \
  build \
  CODE_SIGNING_ALLOWED=NO

# Verified workspace schemes
xcodebuild -workspace Pixlo.xcworkspace -list
```

---

## 5. Build Status

| Target | Result | Notes |
|---|---|---|
| `PixloShared` | ✅ BUILD SUCCEEDED | |
| `PixloCapture` | ✅ BUILD SUCCEEDED | |
| `PixloVCExtension` | ✅ BUILD SUCCEEDED | Compiled; unsigned only |
| `PixloVC` | ✅ BUILD SUCCEEDED | Extension embedded at `Contents/Library/SystemExtensions/` |

**Signed build:** Not validated — provisioning profiles for `vc.pixlo.PixloVC` and `vc.pixlo.PixloVC.Extension` with App Group `group.vc.pixlo.app` have not been created in the Apple Developer portal. See Section 6.

**Compilation errors encountered and resolved:**
- `sendSampleBuffer(_:discontinuity:hostTimeInNanoseconds:)` → renamed to `send(_:discontinuity:hostTimeInNanoseconds:)` in Swift overlay
- `CMIOExtensionStreamProperties.activeFormatIndex` is `Int?` in Swift (not `NSNumber?`)
- `CMIOExtensionStreamProperties.frameDuration` is `CMTime?` in Swift (not `NSDictionary?`)
- `CMIOExtensionStream.DiscontinuityFlags.none` unavailable; use `[]` instead
- CopyFiles phase `dstSubfolderSpec = 16` placed extension outside app bundle; corrected to `dstSubfolderSpec = 1`

---

## 6. Manual Activation Steps Still Required

The following must be completed by the developer before P05 can be tested:

### 6.1 — Developer Portal provisioning

1. Sign in to [developer.apple.com](https://developer.apple.com) with the Apple ID for team `P4KPQ56YNX`.
2. **Create App Group:** `group.vc.pixlo.app`
   - Certificates, Identifiers & Profiles → Identifiers → App Groups → `+`
3. **Register host app App ID:** `vc.pixlo.PixloVC`
   - Enable capability: App Groups → add `group.vc.pixlo.app`
   - Enable capability: System Extension
4. **Register extension App ID:** `vc.pixlo.PixloVC.Extension`
   - Enable capability: App Groups → add `group.vc.pixlo.app`
5. **Create provisioning profiles** for both App IDs (Mac Development).

### 6.2 — Signed build in Xcode

```bash
# Login to Xcode account first (Xcode → Settings → Accounts)
# Then build with signing:
xcodebuild -workspace Pixlo.xcworkspace \
  -scheme PixloVC \
  -configuration Debug \
  build \
  -allowProvisioningUpdates
```

Or open `Pixlo.xcworkspace` in Xcode and build with the Run button.

### 6.3 — Install and approve the extension

1. Launch `PixloVC.app` from the build products.
2. Click **"Install Virtual Camera"** in the status bar.
3. The system will prompt for user approval in **System Settings → Privacy & Security → Security**.
4. Click "Allow" and authenticate when prompted.
5. After approval, the status bar should show **"Virtual camera: active"**.

### 6.4 — Verify the virtual camera appears

```bash
system_profiler SPCameraDataType
```

Should list `"Pixlo VC"` as a camera device.

### 6.5 — Verify synthetic frames are visible

1. Open FaceTime or Zoom.
2. In the camera selector, choose **"Pixlo VC"**.
3. The video feed should show a solid mid-gray frame (the synthetic test pattern).

---

## 7. Known Issues

| Issue | Severity | Notes |
|---|---|---|
| App Group `group.vc.pixlo.app` not provisioned | High | Blocks signed build and extension activation |
| No signed build validated | High | Required before extension can be activated |
| IOSurface transport not implemented | Expected | Deferred to P05; synthetic frames confirm extension registration |
| `ExtensionStatus.unknown` on cold launch | Low | Status reflects actual state only after `install()` is called; no persistence check on launch |

---

## 8. Readiness Verdict

**READY FOR P05**

### Stabilization scope for P05

P05 (Live Passthrough) should implement:

1. **`Packages/PixloShared/Sources/PixloShared/FrameTransport.swift`** — Add `IOSurface` create / lookup / lock helpers and the UserDefaults key for sharing the surface ID via App Group.
2. **`Apps/PixloVC/PixloVC/CaptureViewModel` (or a new `IOSurfaceWriter.swift`)** — Subscribe to `CaptureManager.pixelBufferPublisher`; on each frame, lock IOSurface → copy pixel data → write `IOSurfaceGetID()` to App Group UserDefaults → unlock.
3. **`Apps/PixloVCExtension/VirtualCameraStream.swift`** — In `emitFrame()`, replace the synthetic CVPixelBuffer with: read surface ID from App Group UserDefaults → `IOSurfaceLookup(id)` → lock → wrap in CVPixelBuffer → create CMSampleBuffer → unlock. Fall back to black frame if surface ID not yet available.
4. Both targets must use the **provisioned signed build** (step 6.1 above is a hard prerequisite).

### P05 acceptance checklist

- [ ] Provisioning profiles for host + extension created with App Group
- [ ] Signed build succeeds (no provisioning errors)
- [ ] `OSSystemExtensionManager.activationRequest` completes successfully after user approval
- [ ] `system_profiler SPCameraDataType` lists "Pixlo VC"
- [ ] Live physical camera frames visible through "Pixlo VC" in FaceTime/Zoom (IOSurface passthrough working)
- [ ] No frame queue — latest-frame-wins IOSurface transport confirmed
- [ ] `PixloShared` contains only `AppConstants.swift` + `FrameTransport.swift` (no CameraSettings, no Combine publishers)
- [ ] No transforms, filters, or settings UI introduced
