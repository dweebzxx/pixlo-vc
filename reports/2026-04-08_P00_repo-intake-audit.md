# P00 Repository Intake Audit — Pixlo VC

**Date**: 2026-04-08
**Auditor**: Claude Opus 4.6
**Commit**: ed4f1d4 (main)
**Prompt**: P00 — Repo Intake & Architecture Audit

---

## 1. Executive Verdict

The repository is a well-structured skeleton with coherent documentation and no implementation code. The docs are internally consistent, scope-disciplined, and correctly describe a macOS Camera Extension architecture. However, the repo was generated with a few GitHub/open-source-project assumptions (CONTRIBUTING.md, issue templates, milestone task template) that add process weight inappropriate for a solo/small-team AI-assisted build. There is no Xcode project, no Swift package, no CLAUDE.md, and no `.DS_Store` exclusion in committed files. A light cleanup pass is warranted before implementation begins.

**Verdict: RUN CLEANUP P00A FIRST**

---

## 2. Current Repository Inventory

```
.
├── .DS_Store                          ← committed; should not be
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md             ← premature for pre-alpha
│   │   ├── feature_request.md        ← premature for pre-alpha
│   │   └── milestone_task.md         ← premature for pre-alpha
│   └── PULL_REQUEST_TEMPLATE.md      ← reasonable to keep
├── .gitignore                         ← solid, covers Xcode/SPM/macOS
├── Apps/
│   └── README.md                      ← placeholder doc
├── CONTRIBUTING.md                    ← premature process weight
├── Docs/
│   ├── architecture.md                ← strong; keep
│   ├── qa-matrix.md                   ← strong; keep
│   └── roadmap.md                     ← strong; keep
├── logs/
│   ├── .DS_Store                      ← committed; should not be
│   └── claude/
│       └── 2026-04-08_P00_repo-intake-audit.log  ← session transcript
├── Packages/
│   └── README.md                      ← placeholder doc
├── README.md                          ← good overview
├── reports/                           ← empty (this report goes here)
└── Scripts/
    └── bootstrap.sh                   ← functional env check stub
```

**Total files (excluding .git)**: 16
**Swift source files**: 0
**Xcode project files**: 0

---

## 3. What Is Strong and Should Be Kept

- **`Docs/architecture.md`** — Correct CMIOExtensionProvider architecture. Data flow diagram is accurate. Component breakdown (PixloCapture, PixloRender, PixloShared) is sound. Open decisions are clearly flagged.
- **`Docs/roadmap.md`** — Phased milestones are well-scoped. Out-of-scope table is excellent and directly aligned with the project's "not a streaming suite" constraint. Exit criteria are defined per phase.
- **`Docs/qa-matrix.md`** — Concrete, testable acceptance criteria organized by phase. Good use of IDs (CAP-01, EXT-01, etc.) for traceability.
- **`README.md`** — Clean, accurate, minimal. Correctly references macOS 14+ and Xcode 16+.
- **`.gitignore`** — Comprehensive for Xcode/SPM/macOS. Covers CocoaPods/Carthage defensively.
- **`Scripts/bootstrap.sh`** — Functional. Checks macOS and Xcode versions. Signing check is appropriately stubbed.
- **`.github/PULL_REQUEST_TEMPLATE.md`** — Reasonable template if PRs are used. Lightweight enough to keep.
- **`Apps/README.md`** and **`Packages/README.md`** — Useful placeholder docs that describe what goes where.

---

## 4. What Is Weak, Unclear, or Premature

### Premature process artifacts
- **`CONTRIBUTING.md`** — Defines branch naming, commit conventions, PR process, and code style for external contributors. There are no external contributors. This file adds cognitive overhead and will become stale as the actual development workflow evolves. It should be removed or reduced to a one-liner.
- **`.github/ISSUE_TEMPLATE/bug_report.md`** — No code exists to have bugs in. Premature.
- **`.github/ISSUE_TEMPLATE/feature_request.md`** — Scope is already locked in the roadmap. Premature.
- **`.github/ISSUE_TEMPLATE/milestone_task.md`** — Tracking belongs in the roadmap and prompt chain, not GitHub Issues at this stage. Premature.

### Committed `.DS_Store` files
- `.DS_Store` at repo root and `logs/.DS_Store` are committed despite `.gitignore` listing `.DS_Store`. They were likely committed before the gitignore was in place.

### Missing `CLAUDE.md`
- No `CLAUDE.md` exists. This is the primary mechanism for giving Claude Code project-level context and constraints. Without it, every prompt session starts from scratch with no persistent build rules.

### `logs/` directory
- Contains a session transcript (`logs/claude/2026-04-08_P00_repo-intake-audit.log`). The `.gitignore` already excludes `*.log`, so this file is untracked — but the `logs/` directory structure is committed. This is fine if logs are intended to be local-only, but the directory should have a `.gitkeep` or README explaining its purpose.

### No license file
- README says "TBD". This is fine for now but should be resolved before any public push.

---

## 5. What Should Be Revised or Deleted Before Implementation

### Delete
| Item | Reason |
|---|---|
| `.DS_Store` (root) | macOS artifact, already in .gitignore |
| `logs/.DS_Store` | macOS artifact |
| `CONTRIBUTING.md` | Premature process weight; no external contributors |
| `.github/ISSUE_TEMPLATE/bug_report.md` | No code to have bugs in yet |
| `.github/ISSUE_TEMPLATE/feature_request.md` | Scope is locked; requests go through prompt chain |
| `.github/ISSUE_TEMPLATE/milestone_task.md` | Tracking happens in roadmap/prompts, not GH Issues |

### Create
| Item | Reason |
|---|---|
| `CLAUDE.md` | Essential. Must define: project identity, architecture constraints, coding standards, what NOT to build, prompt chain context |

### Revise
| Item | Change |
|---|---|
| `README.md` | Remove reference to `CONTRIBUTING.md` if deleted. Add note about CLAUDE.md for AI-assisted development. |
| `.github/ISSUE_TEMPLATE/` | Delete directory entirely if all templates are removed |
| `logs/` | Add a `logs/README.md` or `.gitkeep` explaining purpose, or remove if unneeded in repo |

---

## 6. Architecture Alignment Check

| Concern | Status | Notes |
|---|---|---|
| macOS Camera Extension (CMIOExtensionProvider) | Aligned | architecture.md correctly describes the modern API (macOS 12.3+) |
| No OBS-style scene composition | Aligned | Roadmap explicitly defers streaming, NDI, recording |
| Single physical camera in, single virtual out | Aligned | architecture.md notes multi-camera as an open decision; should be closed as "no" for v1 |
| Lightweight scope | Mostly aligned | Issue templates and CONTRIBUTING.md add unnecessary process; otherwise lean |
| Swift packages for shared code | Aligned | PixloCapture, PixloRender, PixloShared are correctly scoped |
| IPC mechanism undecided | Acceptable | Correctly flagged as open decision for Phase 2 |
| Metal vs Core Image undecided | Acceptable | Correctly flagged as open decision for Phase 3 |

### Recommendation on open decision "multiple simultaneous physical cameras"
Close this as **out of scope for v1**. The project spec says "one physical camera input." This should be reflected in `architecture.md`.

---

## 7. Missing Essentials Before P01

1. **`CLAUDE.md`** — Must exist before any implementation prompt. Should contain:
   - Project name and one-line description
   - Architecture summary (host app + camera extension + 3 Swift packages)
   - Coding constraints (Swift, SwiftUI, macOS 14+, no third-party deps)
   - What NOT to build (streaming, recording, plugins, multi-camera)
   - Build/test commands (placeholder until Xcode project exists)
   - Prompt chain context (current phase, what's been completed)

2. **Clean git state** — Remove committed `.DS_Store` files from tracking.

3. **Issue template cleanup** — Remove premature GitHub process artifacts.

---

## 8. Recommended Next Step

**Run prompt P00A** with the following cleanup scope:

### P00A Cleanup Goals
1. Remove `.DS_Store` files from git tracking
2. Delete `CONTRIBUTING.md`
3. Delete `.github/ISSUE_TEMPLATE/` directory (keep `.github/PULL_REQUEST_TEMPLATE.md`)
4. Create `CLAUDE.md` with project constraints and build context
5. Close the "multiple cameras" open decision as out-of-scope in `Docs/architecture.md`
6. Update `README.md` to remove CONTRIBUTING.md reference
7. Commit cleanup as a single clean commit

### P00A Acceptance Checklist
- [ ] No `.DS_Store` in git tracking
- [ ] No `CONTRIBUTING.md`
- [ ] No `.github/ISSUE_TEMPLATE/` directory
- [ ] `CLAUDE.md` exists at repo root with project constraints
- [ ] `architecture.md` closes multi-camera as out-of-scope for v1
- [ ] `README.md` updated
- [ ] Clean commit on main

---

## 9. Readiness Verdict

### RUN CLEANUP P00A FIRST

**Cleanup goals**: Remove premature GitHub process artifacts, remove committed `.DS_Store` files, create `CLAUDE.md` as the foundational project context file for all future AI-assisted implementation prompts.

**Minimal cleanup scope**: 6 files deleted/revised, 1 file created (`CLAUDE.md`), 1 file updated (`README.md`), 1 doc revision (`architecture.md`).

**Specific files/folders involved**:
- DELETE: `.DS_Store`, `logs/.DS_Store`, `CONTRIBUTING.md`, `.github/ISSUE_TEMPLATE/` (3 files)
- CREATE: `CLAUDE.md`
- REVISE: `README.md`, `Docs/architecture.md`
