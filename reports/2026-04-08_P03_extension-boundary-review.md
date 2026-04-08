# P03 — Extension Boundary Review

**Date:** 2026-04-08
**Branch:** `docs/p03-extension-boundary-review`
**Prompt ID:** P03

---

## 1. Current Implementation State Reviewed

### Repo structure (post-P01/P02 merge to main)

```
Apps/PixloVC/
  PixloVC.xcodeproj/          Xcode project (links PixloCapture as local package)
  PixloVC/
    PixloVCApp.swift           @main SwiftUI entry point
    ContentView.swift          State-driven UI + CaptureViewModel
    CameraPreviewView.swift    NSViewRepresentable wrapping AVCaptureVideoPreviewLayer
    Info.plist                 NSCameraUsageDescription
Packages/PixloCapture/
  Package.swift                swift-tools-version 5.10, macOS 14+
  Sources/PixloCapture/
    CaptureManager.swift       AVCaptureSession wrapper; CVPixelBuffer via Combine
    CapturePermission.swift    Async TCC permission helper
Pixlo.xcworkspace/             Root workspace referencing app project + PixloCapture
Scripts/bootstrap.sh           Environment validator
Docs/                          architecture.md, roadmap.md, qa-matrix.md
reports/                       P00, P01, P02 reports
```

### What works

- `PixloCapture` builds standalone (`swift build`) and as part of the workspace.
- Host app builds unsigned (`xcodebuild -workspace Pixlo.xcworkspace -scheme PixloVC CODE_SIGNING_ALLOWED=NO`).
- `CaptureManager` emits `CVPixelBuffer` frames via `PassthroughSubject`.
- Live preview renders via `AVCaptureVideoPreviewLayer`.
- Permission denied / no-camera states handled in the UI.

### What does not exist yet

- No Camera Extension target (`Apps/PixloVCExtension`).
- No `PixloShared` package.
- No `PixloRender` package.
- No App Group entitlements.
- No code signing configuration.
- No IPC mechanism.

---

## 2. Key Architecture Decisions

### D1 — Package/module boundaries for P04

**Decision:** P04 adds exactly two new compilation units:

1. **`Apps/PixloVCExtension/`** — System Extension target (CMIOExtensionProvider). Embedded inside the host app bundle.
2. **`Packages/PixloShared/`** — Minimal shared constants package, consumed by both the host app and the extension.

**Not added in P04:** `PixloRender`. There are no transforms in the passthrough milestone. Adding it now would be speculative.

### D2 — Extension activation logic location

**Decision:** Extension activation (via `SystemExtensions.framework`) lives in the host app, not in a package.

Specifically: a new file in `Apps/PixloVC/PixloVC/` (e.g., `ExtensionInstaller.swift`) that calls `OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier:queue:)`. The host app owns the install/activate/deactivate lifecycle.

**Rationale:** This code is host-app-specific (needs the extension's bundle identifier, handles system prompts). It has no reuse case. A package would be pure overhead.

### D3 — PixloShared: yes, but minimal

**Decision:** Create `Packages/PixloShared` in P04 with exactly:

- `AppConstants.swift` — App Group identifier constant (`group.vc.pixlo.app`, placeholder until team ID is confirmed), extension bundle identifier constant.
- `FrameTransport.swift` — The IOSurface coordination contract: surface ID storage key, lock/unlock helpers around `IOSurfaceLock`/`IOSurfaceUnlock`.

**Not included:** `CameraSettings`, Combine publishers, UserDefaults wrappers beyond the surface ID. Those belong to Phase 3 (transforms) when settings actually exist.

### D4 — Frame transport: IOSurface with latest-frame-wins

**Decision:** Use `IOSurface` shared memory for host-to-extension frame transport.

**Mechanism:**

1. Host app creates an `IOSurface` (BGRA, matching capture resolution).
2. Host writes `IOSurfaceGetID()` to App Group `UserDefaults`.
3. Extension calls `IOSurfaceLookup(id)` to obtain the shared surface.
4. On each captured frame, host locks the surface (`IOSurfaceLock`), copies the `CVPixelBuffer` contents, unlocks (`IOSurfaceUnlock`).
5. Extension runs a `DispatchSourceTimer` at target frame rate. On each tick: lock surface, wrap backing memory in a `CVPixelBuffer`, create `CMSampleBuffer`, send to `CMIOExtensionStream`, unlock.
6. **Latest-frame-wins.** No ring buffer, no queue, no back-pressure. If the extension reads mid-write, it gets a torn frame — acceptable for v1 passthrough where both sides run at ~30 fps and tearing is rare in practice.

**Rejected alternatives:**

| Alternative | Why rejected |
|---|---|
| XPC with serialized pixel data | Full frame copy per transfer (~6 MB/frame at 1080p BGRA). Adds latency and CPU overhead that IOSurface avoids entirely. |
| XPC + Mach port for IOSurface handle | More correct than UserDefaults for surface ID sharing, but adds XPC service boilerplate. The IOSurfaceID is a system-wide uint32; UserDefaults in an App Group is sufficient and simpler. Can upgrade to Mach port passing later if needed. |
| Extension captures camera directly | Avoids IPC entirely but contradicts the architecture ("keep extension lean, heavy processing in host"). Would require moving capture back to host when transforms are added, wasting the work. |
| Ring buffer / triple buffering | Overkill for latest-frame-wins. Adds complexity with no user-visible benefit at v1 frame rates. |
| `CVPixelBufferPool` + `IOSurface`-backed pool | Useful optimization but premature. Start with a single surface; add pooling only if profiling shows contention. |

### D5 — P04 starts with synthetic frames, then wires live passthrough

**Decision:** P04 implementation proceeds in two internal checkpoints:

1. **Checkpoint A — Synthetic output.** Extension skeleton with CMIOExtensionProvider/Device/Stream. Emits a solid-color test pattern. Validates: extension registers, virtual camera appears in system camera list, video apps can select it and see frames.

2. **Checkpoint B — Live passthrough.** Wire IOSurface transport. Host captures physical camera → writes to IOSurface → extension reads and emits. Validates: live camera frames visible in a consuming app through the virtual camera.

Both checkpoints ship in a single P04 commit. The synthetic step is a build/validation waypoint, not a separate phase.

### D6 — Non-goals deferred until after passthrough works

These are explicitly blocked from P04:

| Deferred item | Deferred to |
|---|---|
| `PixloRender` package | Phase 3 (transforms) |
| `CameraSettings` model | Phase 3 |
| Crop / zoom / mirror / rotate UI or logic | Phase 3 |
| Frame rate throttle | Phase 3 |
| Brightness / contrast / grayscale filters | Phase 4 |
| Settings persistence via App Group UserDefaults | Phase 3 (settings don't exist yet) |
| Extension crash recovery / restart UI | Phase 5 |
| Onboarding flow | Phase 5 |
| Menubar icon | Phase 5 |
| Unit tests for extension | Phase 5 (extension requires signed builds to test) |

### D7 — Build, signing, and App Group assumptions

| Assumption | Detail |
|---|---|
| Code signing required | Camera Extensions cannot be loaded unsigned. P04 requires a valid Apple Development or Developer ID signing identity. |
| Host app entitlement | `com.apple.developer.system-extension.install` — required to call `OSSystemExtensionRequest`. |
| Extension entitlement | `com.apple.security.application-groups` — required for App Group UserDefaults access. |
| Host app entitlement | `com.apple.security.application-groups` — same App Group as extension. |
| Camera entitlement | Extension needs `NSCameraUsageDescription` in Info.plist only if it were to capture directly (it won't — host app captures). |
| App Group ID | `group.vc.pixlo.app` (placeholder — actual ID depends on team/provisioning). |
| Host bundle ID | `vc.pixlo.PixloVC` |
| Extension bundle ID | `vc.pixlo.PixloVC.Extension` |
| Extension embedding | Extension `.appex` must be in `Contents/Library/SystemExtensions/` inside the host app bundle. |
| Hardened Runtime | Required for notarization. Enable in P04 but do not block on notarization until P05. |
| Sandbox | Host app: **not sandboxed** for P04 (simplifies System Extension installation). Extension: inherently sandboxed by the system. |
| macOS floor | 14.0 (Sonoma) — confirmed. CMIOExtensionProvider available since 12.3; 14.0 gives us Swift concurrency + SwiftUI features. |

---

## 3. Rejected Alternatives (summary)

| Proposal | Verdict | Reason |
|---|---|---|
| Capture in the extension directly | Rejected | Contradicts architecture; would need rework when transforms land |
| XPC for frame data | Rejected | ~6 MB copy per frame; IOSurface is zero-copy |
| Defer PixloShared to Phase 3 | Rejected | App Group constant and IOSurface coordination need to be shared in P04 |
| Create PixloRender now | Rejected | No transforms in P04; speculative |
| Triple-buffer ring | Rejected | Complexity without user-visible gain at v1 frame rates |
| Named pipes / Unix sockets | Rejected | Worse latency than IOSurface; still requires serialization |

---

## 4. Recommended Next Implementation Shape

P04 should produce:

```
Apps/PixloVCExtension/
  Info.plist
  PixloVCExtension.entitlements
  PixloVCExtension.swift           CMIOExtensionProvider entry point (main)
  VirtualCameraProvider.swift      CMIOExtensionProviderSource
  VirtualCameraDevice.swift        CMIOExtensionDeviceSource
  VirtualCameraStream.swift        CMIOExtensionStreamSource + timer + IOSurface read

Apps/PixloVC/PixloVC/
  ExtensionInstaller.swift         OSSystemExtensionRequest wrapper
  PixloVC.entitlements             system-extension.install + app-groups
  (ContentView.swift updated)      UI for install/status indicator

Packages/PixloShared/
  Package.swift
  Sources/PixloShared/
    AppConstants.swift             App Group ID, extension bundle ID
    FrameTransport.swift           IOSurface create/lookup/lock helpers
```

Host app changes:
- Subscribe to `CaptureManager.pixelBufferPublisher`
- On each frame, lock IOSurface → copy pixel data → unlock
- Add extension install button / status in UI

---

## 5. Exact Scope for P04

**Objective:** A virtual camera device registered with macOS, visible to video-conferencing apps, displaying live frames from the physical camera via IOSurface shared memory.

**Acceptance checklist:**

- [ ] Extension target builds as part of the workspace
- [ ] Extension embedded in host app bundle at `Contents/Library/SystemExtensions/`
- [ ] Signed host app can install extension via SystemExtensions framework
- [ ] Virtual camera appears in `system_profiler SPCameraDataType` after installation
- [ ] Synthetic test pattern visible in FaceTime/Zoom when virtual camera selected (checkpoint A)
- [ ] Live physical camera frames visible through virtual camera (checkpoint B)
- [ ] No frame queue or ring buffer — latest-frame-wins IOSurface transport
- [ ] `PixloShared` package contains only App Group constant + IOSurface helpers
- [ ] No transforms, filters, settings UI, or CameraSettings model
- [ ] Host app has extension install/activate UI (minimal — button + status text)

**Files/modules involved:**

| New | Modified |
|---|---|
| `Apps/PixloVCExtension/` (all files) | `Apps/PixloVC/PixloVC.xcodeproj/project.pbxproj` |
| `Packages/PixloShared/` (all files) | `Apps/PixloVC/PixloVC/ContentView.swift` |
| | `Pixlo.xcworkspace/contents.xcworkspacedata` |

---

## 6. Risk Notes

| Risk | Severity | Mitigation |
|---|---|---|
| Signing identity not available | **High** | P04 cannot be validated without signing. Must have an Apple Development certificate before starting. Document as a hard prerequisite. |
| IOSurface ID lookup across processes | Low | `IOSurfaceLookup()` is a public API and works across processes on macOS. Well-documented in Apple sample code. |
| App Group provisioning not configured | Medium | Need a provisioning profile with App Group capability. Can use automatic signing in Xcode if a team is configured. |
| Extension activation requires user approval | Low | Expected macOS behavior. System prompts are part of the flow. |
| Torn frames under load | Low | Acceptable for v1. Both sides run at ~30 fps; lock duration is sub-millisecond. Triple buffering can be added later if profiling shows tearing. |
| Extension not killed when host quits | Medium | macOS may keep the extension alive. P04 should handle this gracefully (extension shows last frame or black). Crash recovery UI deferred to P05. |

---

## 7. Readiness Verdict

**READY FOR P04**

### P04 implementation objective

Create and register a Camera Extension that passes live physical camera frames to video-conferencing apps via IOSurface shared memory, using a latest-frame-wins transport with no transform pipeline.

### Files/modules likely involved

See Section 5 table above.

### P04 acceptance checklist

See Section 5 checklist above.

### Hard prerequisites for P04

1. Apple Development signing identity available in Keychain.
2. Team ID configured in Xcode (for automatic provisioning / App Group).
3. Physical camera available on the build machine for live passthrough testing.
