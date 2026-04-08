# Pixlo VC

A lightweight virtual camera for macOS with real-time framing, resizing, crop/zoom, mirror controls, and lightweight filters. Designed for low overhead and simplicity — not a streaming suite.

---

## Overview

Pixlo VC uses the macOS Camera Extension API (System Extension + CoreMediaIO DAL replacement) to present a virtual camera device that any video-conferencing app can consume. A companion host app provides the controls UI and shares settings with the extension in real time.

## Repository Layout

```
Apps/          Host macOS application (SwiftUI + AppKit)
Packages/      Reusable Swift packages (shared between app and extension)
Docs/          Architecture, roadmap, and QA matrix
Scripts/       Dev tooling and bootstrap helpers
.github/       PR template and issue templates
```

## Docs

| Document | Description |
|---|---|
| [Architecture](Docs/architecture.md) | Component overview and data-flow diagram |
| [Roadmap](Docs/roadmap.md) | Phased milestones and scope boundaries |
| [QA Matrix](Docs/qa-matrix.md) | Test categories and acceptance criteria |

## Getting Started

1. **Requirements**: macOS 14+, Xcode 16+, an Apple Developer account with the Camera Extension entitlement.
2. **Bootstrap**: Run `Scripts/bootstrap.sh` to verify your environment (stub — see script for details).
3. Open the workspace once it exists: `open Pixlo.xcworkspace`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

TBD — license will be confirmed before the first tagged release.
