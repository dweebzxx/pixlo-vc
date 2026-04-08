# Contributing to Pixlo VC

Thank you for your interest in contributing! Please read this document before opening issues or pull requests.

---

## Ground Rules

- Keep changes focused and minimal. One concern per PR.
- No speculative code — if a decision hasn't been made, leave it as a TODO with context.
- Follow Swift API Design Guidelines for all Swift code.
- All new public symbols must have a doc-comment.

## Branching

| Branch | Purpose |
|---|---|
| `main` | Stable, reviewed code |
| `copilot/*` | AI-assisted feature branches |
| `dev/*` | Human-authored feature branches |
| `fix/*` | Bug-fix branches |

## Pull Requests

1. Fill in the PR template completely.
2. Link the related issue (required).
3. All checklist items in the template must be addressed before requesting review.
4. Squash-merge is preferred to keep history clean.

## Issues

Use the provided issue templates:
- **Bug report** — unexpected behaviour or crash.
- **Feature request** — new capability proposal.
- **Milestone task** — implementation work tracked against the roadmap.

## Code Style

- `swiftformat` will be added to the toolchain; run it before committing once it is configured.
- Prefer value types (`struct`, `enum`) over reference types unless identity or shared mutable state is explicitly needed.
- Extensions in separate files, named `TypeName+Purpose.swift`.

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

```
feat: add mirror toggle to settings panel
fix: correct aspect-ratio rounding in crop engine
docs: clarify Camera Extension entitlement requirements
chore: update .gitignore for SPM artifacts
```

## Open Decisions

See [Docs/roadmap.md](Docs/roadmap.md) for a list of deferred decisions that need resolution before implementation.
