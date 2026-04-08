# QA Matrix — Pixlo VC

> This matrix defines what "done" means for each area of the product. Update it alongside code changes; it is the acceptance-criteria contract between implementation and review.

---

## Legend

| Symbol | Meaning |
|---|---|
| ✅ | Covered (automated or manual procedure defined) |
| 🔲 | Planned — not yet implemented |
| ❌ | Out of scope / won't test at this level |
| ⚠️ | Needs decision before approach can be chosen |

---

## Phase 1 — Capture

| ID | Area | Test Type | Criterion | Status |
|---|---|---|---|---|
| CAP-01 | Camera permission | Manual | App requests permission on first launch; denial shows graceful error state | 🔲 |
| CAP-02 | Session start | Unit | `CaptureManager.start()` transitions to `.running` state | 🔲 |
| CAP-03 | Session stop | Unit | `CaptureManager.stop()` transitions to `.stopped`; no resource leak | 🔲 |
| CAP-04 | Frame delivery | Unit | `CVPixelBuffer` publisher emits frames at configured rate (≥ 1 fps in test) | 🔲 |
| CAP-05 | No physical camera | Manual | App displays clear error when no camera hardware is present | 🔲 |
| CAP-06 | Preview render | Manual | Live preview visible in host app window within 2 s of launch | 🔲 |

---

## Phase 2 — Virtual Camera Extension

| ID | Area | Test Type | Criterion | Status |
|---|---|---|---|---|
| EXT-01 | Extension install | Manual | System prompts to allow extension; virtual device appears in system camera list after approval | 🔲 |
| EXT-02 | Extension uninstall | Manual | Virtual device disappears from camera list after deactivation; no zombie process | 🔲 |
| EXT-03 | Frame passthrough | Manual | Raw frames from physical camera appear in Zoom / FaceTime when virtual camera is selected | 🔲 |
| EXT-04 | IPC reliability | Integration | No frame drops > 1 % at 30 fps over a 60-second session | 🔲 |
| EXT-05 | Extension crash recovery | Manual | If extension crashes, host app detects and offers restart | 🔲 |
| EXT-06 | Multi-app usage | Manual | Virtual camera usable by two conferencing apps simultaneously (or error is graceful) | 🔲 |

---

## Phase 3 — Transforms

| ID | Area | Test Type | Criterion | Status |
|---|---|---|---|---|
| TRN-01 | Crop | Unit | Output buffer dimensions match expected crop rect to within 1 px | 🔲 |
| TRN-02 | Zoom | Unit | Zoom factor applied correctly; no black bars outside valid range | 🔲 |
| TRN-03 | Mirror | Unit | Horizontal mirror produces pixel-accurate reflection of input | 🔲 |
| TRN-04 | Frame rate | Unit | Frame-rate throttle drops to within ±2 fps of target | 🔲 |
| TRN-05 | Settings sync | Integration | Change in host app UI reflected in virtual camera output within 1 frame | 🔲 |
| TRN-06 | CPU overhead | Performance | Render pipeline adds ≤ 10 % CPU vs. Phase 2 baseline at 1080p 30 fps | 🔲 |

---

## Phase 4 — Filters

| ID | Area | Test Type | Criterion | Status |
|---|---|---|---|---|
| FLT-01 | Brightness | Unit | Output pixel values match expected linear mapping at ±50 % brightness | 🔲 |
| FLT-02 | Contrast | Unit | Output pixel values match expected contrast curve | 🔲 |
| FLT-03 | Grayscale | Unit | All output pixels satisfy R == G == B (within float precision) | 🔲 |
| FLT-04 | Blur | Visual | Soft blur visually perceptible at radius 5 px; no artefacts at edges | 🔲 |
| FLT-05 | Filter CPU overhead | Performance | Filters add ≤ 5 % CPU vs. Phase 3 baseline | 🔲 |
| FLT-06 | Filter off | Unit | Disabling all filters produces output identical to unfiltered input | 🔲 |

---

## Phase 5 — Polish

| ID | Area | Test Type | Criterion | Status |
|---|---|---|---|---|
| POL-01 | Onboarding | Manual | First-launch flow covers permissions + extension install in ≤ 3 steps | 🔲 |
| POL-02 | Settings persistence | Integration | All settings survive app quit + relaunch | 🔲 |
| POL-03 | Menubar icon | Manual | Quick controls accessible from menubar without opening main window | 🔲 |
| POL-04 | Crash rate | Manual / Instrument | Zero crashes in 30-minute continuous use internal test | 🔲 |
| POL-05 | Notarisation | CI | Build passes `spctl --assess` check | 🔲 |
| POL-06 | Memory growth | Instrument | No steady memory growth over 10-minute session (Instruments Leaks) | 🔲 |

---

## Cross-cutting

| ID | Area | Test Type | Criterion | Status |
|---|---|---|---|---|
| CRX-01 | Accessibility | Manual | All interactive controls reachable via VoiceOver | 🔲 |
| CRX-02 | Dark mode | Manual | UI renders correctly in both light and dark mode | 🔲 |
| CRX-03 | Multiple users | Manual | App works correctly under Fast User Switching | 🔲 |
| CRX-04 | macOS upgrade | Manual | App functions after minor macOS point release | 🔲 |

---

## Open Decisions Affecting QA

- Performance baselines (CPU %) depend on target hardware — define a reference Mac (e.g., M1 MacBook Pro) before Phase 3 testing.
- Integration tests for extension IPC require a signed build; cannot run in a standard CI sandbox without entitlements.
