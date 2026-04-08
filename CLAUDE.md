# CLAUDE.md — Pixlo VC

> This file is the operating guide for AI-assisted development of this repository. Read it at the start of every session.

---

## Project Identity

**Pixlo VC** is a lightweight virtual camera for macOS.
One physical camera in → real-time transform → one virtual camera out.
Not a streaming suite. Not OBS. Not a plugin platform.

---

## v1 Scope

| In scope | Out of scope |
|---|---|
| One physical AVCaptureDevice input | Multiple simultaneous physical cameras |
| One CMIOExtensionProvider virtual output | Scene composition / chroma key |
| Crop / zoom / pan / fit-fill | Recording to disk |
| Mirror (horizontal flip) | Streaming (RTMP, NDI, SRT) |
| Rotate (90° increments) | Browser capture sources |
| Brightness / contrast / grayscale | Third-party plugins or extensions |
| Frame rate passthrough | Snapshots / screenshot exports |
| Minimal system overhead | App Store distribution (Phase 5 decision) |

---

## Architecture Summary

```
Physical Camera (AVCaptureDevice)
    │  AVCaptureVideoDataOutput → CVPixelBuffer
    ▼
PixloCapture  (Packages/PixloCapture)
    │  CVPixelBuffer (raw)
    ▼
PixloRender   (Packages/PixloRender) ◄── CameraSettings (PixloShared)
    │  CVPixelBuffer (processed)
    ▼
IOSurface  (shared memory, latest-frame-wins)
    │
    ▼
Camera Extension (CMIOExtensionProvider) → CMIOStream → video app
```

**Components:**
- `Apps/PixloVC` — SwiftUI host app; controls UI, capture session, extension install
- `Apps/PixloVCExtension` — System Extension; CMIOExtensionProvider/Device/Stream
- `Packages/PixloCapture` — AVCaptureSession wrapper, emits CVPixelBuffer frames
- `Packages/PixloRender` — crop/zoom/mirror/filter; Metal compute or Core Image
- `Packages/PixloShared` — CameraSettings (Codable), App Group UserDefaults, Combine publisher

**Platform:** macOS 14+ (Sonoma), Swift 5.10+, Xcode 16+
**No third-party dependencies** for v1.

---

## Coding Constraints

- **Swift only.** No Objective-C unless a system API requires a bridging header.
- **SwiftUI for UI.** AppKit only where SwiftUI cannot reach (e.g. menu bar extras).
- **No third-party packages** for v1. Use only Apple frameworks.
- **No speculative abstractions.** Write what the current phase requires; no plugin hooks, no protocol layers for hypothetical future sources.
- **Prefer readable over clever.** If a simpler implementation exists, use it.
- **Keep files small.** If a file exceeds ~200 lines, consider decomposition.
- **No recording, streaming, or browser source code.** Reject any generated code that drifts toward these.
- **Camera Extension requires signing.** Extension milestones cannot be validated unsigned. Do not attempt to build/test the extension with `CODE_SIGNING_ALLOWED=NO`.

---

## Repo Working Rules

1. **Follow the prompt chain.** Implementation phases are P01, P02, P03, P04, P05. Do not skip phases or implement future-phase features to be "helpful."
2. **Read this file and the relevant Docs/ before writing any code.** Do not invent architecture that contradicts `Docs/architecture.md`.
3. **One commit per prompt.** Keep commits scoped to what the prompt asked for.
4. **Reports go in `reports/`.** Named `YYYY-MM-DD_<PROMPT-ID>_<slug>.md`.
5. **Do not create the Xcode project** unless the current prompt explicitly requires it.
6. **Do not add CI** (GitHub Actions, Fastlane, etc.) until explicitly requested.
7. **Do not add issue templates, contributor guides, or changelog management** — this is a solo/small-team AI-assisted build, not an OSS project.
8. **Logs are local artifacts.** `logs/` is for session transcripts; files are untracked (`.log` excluded by `.gitignore`).

---

## Non-Goals (permanent)

These are not on the roadmap at any phase:

- OBS-style scene composition
- Recording to disk (any format)
- Streaming output (RTMP, NDI, SRT, WebRTC)
- Browser/application window capture sources
- Third-party plugin architecture
- Multiple simultaneous physical camera inputs (v1)
- iOS / iPadOS port
- Mac App Store distribution (undecided — do not assume either way)

---

## Current Phase

**Phase 1 — Capture** (complete after P02)

Next: **P04 — Virtual Camera Extension**: Camera Extension with IOSurface passthrough. Requires signed build. See `reports/2026-04-08_P03_extension-boundary-review.md` for decisions and scope.
