# P02 — Capture Stabilization Report

**Date:** 2026-04-08  
**Branch:** `feat/p01-capture-preview`  
**Prompt ID:** P02

## 1. Starting state inspected

- Read: `CLAUDE.md`, `README.md`, `Docs/architecture.md`, `Docs/roadmap.md`, `reports/2026-04-08_P01_capture-preview-report.md`
- Git branch at start: `feat/p01-capture-preview`
- Git worktree at start: clean
- Diff inspected against `main...HEAD`: P01 added the host app project/workspace, `PixloCapture`, and the P00/P01 reports
- Actual Xcode objects discovered:
  - Workspace: `Pixlo.xcworkspace`
  - Project: `Apps/PixloVC/PixloVC.xcodeproj`
  - Workspace schemes: `PixloCapture`, `PixloVC`
  - Project target/scheme: `PixloVC`
- Relevant tests discovered: none under `Tests/`

## 2. Validation commands run

```bash
bash Scripts/bootstrap.sh

find . -maxdepth 3 \( -name '*.xcworkspace' -o -name '*.xcodeproj' \) | sort

xcodebuild -list -workspace Pixlo.xcworkspace
xcodebuild -list -project Apps/PixloVC/PixloVC.xcodeproj

swift build
# run from: Packages/PixloCapture

xcodebuild -workspace Pixlo.xcworkspace \
  -scheme PixloVC \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build
```

## 3. Issues found

1. `Scripts/bootstrap.sh` still printed a stale Phase 0 message saying `Pixlo.xcworkspace` did not exist.
2. `CameraPreviewView.updateNSView` was a no-op, so SwiftUI updates did not reapply the active `AVCaptureSession` to the preview layer host view.
3. `CaptureManager.start()` and `stop()` did not share a dedicated serial session queue, and startup configuration was not guarded against duplicate calls.
4. Capture failures surfaced through `error.localizedDescription`, but `CaptureError` did not provide user-facing descriptions.
5. No milestone-specific tests exist yet, so validation for P01 remains build-focused.

## 4. Fixes applied

- Updated `Scripts/bootstrap.sh` to point to the real workspace instead of the pre-P01 placeholder text.
- Updated `Apps/PixloVC/PixloVC/CameraPreviewView.swift` so `updateNSView` reapplies the current session.
- Hardened `Packages/PixloCapture/Sources/PixloCapture/CaptureManager.swift`:
  - added a dedicated serial `sessionQueue`
  - moved `startRunning` / `stopRunning` onto that queue
  - made configuration idempotent within the current lifecycle
  - added `LocalizedError` messages for capture failures
- Updated `Apps/PixloVC/PixloVC/ContentView.swift`:
  - stop capture on view disappearance
  - guard repeated startup work from duplicate SwiftUI task execution

## 5. Remaining warnings or blockers

- `Scripts/bootstrap.sh` still emits two expected placeholder warnings about signing identity and App Group provisioning. These are accurate for the current phase and are not blockers for P01 stabilization.
- `xcodebuild` under Xcode 26 still emits:
  - `warning: Metadata extraction skipped. No AppIntents.framework dependency found.`
  This is a non-blocking build-system warning; it does not affect the host app or `PixloCapture` output for P01.
- There are still no unit tests for `PixloCapture`. This remains a gap, but adding a new test harness was outside this prompt’s scope.

## 6. Final build status

- `bash Scripts/bootstrap.sh`: passed
- `swift build` in `Packages/PixloCapture`: passed
- `xcodebuild` for workspace `Pixlo.xcworkspace`, scheme `PixloVC`, Debug, unsigned, macOS arm64 destination: passed
- Relevant tests: none present

## 7. Readiness verdict

**READY FOR P03**

- Branch ready to review and merge: yes
- Exact architectural question P03 should answer next:
  - Which host-to-extension frame transport should Pixlo VC adopt for raw preview frames in Phase 2: XPC message passing or `IOSurface`-backed shared memory?
