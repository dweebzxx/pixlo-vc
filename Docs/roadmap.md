# Roadmap — Pixlo VC

> This roadmap defines phased milestones and explicit scope boundaries. Anything not listed here is **out of scope** until the roadmap is revised.

---

## Guiding Principles

- Ship each phase as a working, testable slice before starting the next.
- Prefer Apple-native APIs over third-party dependencies.
- Keep the extension lean — heavy processing belongs in the host app.
- No feature is "done" until it passes the [QA Matrix](qa-matrix.md).

---

## Phase 0 — Skeleton *(current)*

**Goal**: Clean, coherent repository structure ready for implementation.

- [x] README, architecture, roadmap, QA matrix docs
- [x] CONTRIBUTING and PR/issue templates
- [x] `.gitignore` for Xcode/macOS
- [x] Placeholder folders: `Apps/`, `Packages/`, `Scripts/`
- [x] `Scripts/bootstrap.sh` stub
- [ ] Xcode workspace and project files
- [ ] App Group provisioning placeholder (entitlements files)

**Exit criterion**: A new contributor can clone the repo, read the docs, and know exactly what to build next.

---

## Phase 1 — Capture

**Goal**: Physical camera capture with live preview inside the host app.

- [ ] `PixloCapture` Swift package
  - `AVCaptureSession` lifecycle management
  - Camera permission handling
  - `CVPixelBuffer` publisher (Combine)
- [ ] Host app skeleton (`PixloVCApp`, `ContentView`, `CaptureManager`)
- [ ] Live preview using `AVCaptureVideoPreviewLayer` or Metal view
- [ ] Unit tests for `PixloCapture`

**Out of scope for this phase**: virtual camera, transforms, filters.

---

## Phase 2 — Virtual Camera Extension

**Goal**: A virtual CMIODevice visible to the system; it mirrors raw frames from the physical camera.

- [ ] `PixloVCExtension` system extension target
- [ ] `CMIOExtensionProvider` / `CMIOExtensionDevice` implementation
- [ ] IPC between host app and extension (mechanism selected from open decisions)
- [ ] Host app can install/activate/deactivate the extension
- [ ] Virtual camera selectable in Zoom / FaceTime

**Out of scope**: transforms, filters, settings UI.

---

## Phase 3 — Transforms

**Goal**: Crop/zoom, mirror, and frame-rate control applied to the virtual camera output.

- [ ] `PixloRender` Swift package
  - Crop/zoom (Metal compute shader or `CIFilter` — TBD)
  - Mirror transform
  - Frame-rate throttle
- [ ] `PixloShared` package for `CameraSettings` model + App Group persistence
- [ ] Settings UI in host app (sliders, toggles)
- [ ] Settings changes reflected in virtual camera output within one frame

---

## Phase 4 — Filters

**Goal**: Lightweight, real-time image filters.

- [ ] Brightness / contrast adjustment
- [ ] Grayscale / sepia
- [ ] Soft blur (background simulation — no segmentation)
- [ ] Filter pipeline composable with transform pipeline
- [ ] Performance: ≤ 5 % additional CPU overhead vs. Phase 3 baseline

**Out of scope**: AI-based background replacement, LUT-based colour grading (future phases).

---

## Phase 5 — Polish & Distribution

**Goal**: Ready for first public release.

- [ ] Onboarding flow (permission requests, extension install)
- [ ] Menubar icon with quick controls
- [ ] Settings persistence across launches
- [ ] Crash-free for 95 % of sessions in internal testing
- [ ] Code-signed and notarised build
- [ ] README updated with download/install instructions
- [ ] License confirmed and added

---

## Out of Scope (explicitly deferred / rejected)

| Feature | Reason |
|---|---|
| RTMP / streaming output | Out of product scope — use OBS |
| NDI / SRT protocol support | Complexity; may revisit post-v1 |
| AI background segmentation | Too resource-heavy for v1 |
| LUT colour grading | Nice-to-have, Phase 6+ |
| iOS / iPadOS support | macOS-only for v1 |
| Windows / Linux | macOS-only product |
| Built-in recording | Use QuickTime; not our problem to solve |
| Remote camera (network) | Out of scope |

---

## Open Decisions

1. **IPC mechanism** (Phase 2) — XPC service vs. `IOSurface` + shared memory. Affects latency and code complexity.
2. **Render tech** (Phase 3) — Metal compute vs. Core Image. Affects filter expressiveness and performance floor.
3. **Minimum macOS version** — 14.0 (Sonoma) vs. 15.0 (Sequoia). The CoreMediaIO Camera Extension API is available from macOS 12.3, but a higher minimum (14+) is documented here to allow use of Swift structured concurrency and SwiftUI features that require Sonoma; the final floor will be confirmed in Phase 1.
4. **App Group ID** — needs team ID; placeholder until signing is configured.
5. **Distribution** — direct (no sandboxing restriction) vs. Mac App Store (full sandbox, complicates System Extension).
