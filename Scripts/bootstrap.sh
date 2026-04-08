#!/usr/bin/env bash
# Scripts/bootstrap.sh
# ---------------------
# Verifies the development environment for Pixlo VC.
# Run this script before opening the Xcode workspace for the first time.
#
# Status: STUB — extend this script as the project matures.

set -euo pipefail

REQUIRED_MACOS_MAJOR=14
REQUIRED_XCODE_MAJOR=16

# ── Helpers ────────────────────────────────────────────────────────────────

pass() { echo "  ✅  $*"; }
warn() { echo "  ⚠️   $*"; }
fail() { echo "  ❌  $*"; exit 1; }

echo ""
echo "Pixlo VC — bootstrap check"
echo "──────────────────────────"

# ── macOS version ──────────────────────────────────────────────────────────

MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)

if [ "$MACOS_MAJOR" -ge "$REQUIRED_MACOS_MAJOR" ]; then
  pass "macOS $MACOS_VERSION (requirement: $REQUIRED_MACOS_MAJOR+)"
else
  fail "macOS $MACOS_VERSION is too old. Upgrade to $REQUIRED_MACOS_MAJOR or later."
fi

# ── Xcode ──────────────────────────────────────────────────────────────────

if ! command -v xcodebuild &>/dev/null; then
  fail "xcodebuild not found. Install Xcode $REQUIRED_XCODE_MAJOR+ from the App Store."
fi

XCODE_VERSION=$(xcodebuild -version 2>/dev/null | awk '/^Xcode/ {print $2}')
XCODE_MAJOR=$(echo "$XCODE_VERSION" | cut -d. -f1)

if [ "$XCODE_MAJOR" -ge "$REQUIRED_XCODE_MAJOR" ]; then
  pass "Xcode $XCODE_VERSION (requirement: $REQUIRED_XCODE_MAJOR+)"
else
  fail "Xcode $XCODE_VERSION is too old. Install Xcode $REQUIRED_XCODE_MAJOR or later."
fi

# ── Developer account / signing (placeholder) ─────────────────────────────

warn "Signing identity check not yet implemented — ensure you have a Developer ID certificate."
warn "App Group entitlement requires a provisioning profile; configure manually in Xcode."

# ── Done ───────────────────────────────────────────────────────────────────

echo ""
echo "Bootstrap check complete."
echo "Next step: open Pixlo.xcworkspace in Xcode (not yet created — see Phase 1)."
echo ""
