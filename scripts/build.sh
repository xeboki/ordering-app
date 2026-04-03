#!/usr/bin/env bash
# =============================================================================
# Xeboki Ordering App — Build Script
#
# Usage:
#   bash scripts/build.sh android         → debug APK
#   bash scripts/build.sh android release → release APK
#   bash scripts/build.sh android aab     → release AAB (for Play Store)
#   bash scripts/build.sh ios             → release IPA (macOS + Xcode required)
#   bash scripts/build.sh ios debug       → debug build
#   bash scripts/build.sh web             → web build (serve via any static host)
#
# Prerequisites:
#   - .dart_defines.json must exist (run setup.sh first, or copy the example)
#   - For release Android: android/key.properties + keystore file (see SETUP.md)
#   - For iOS:  macOS, Xcode ≥ 15, valid provisioning profile
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${CYAN}  $*${NC}"; }
success() { echo -e "${GREEN}  ✓ $*${NC}"; }
warn()    { echo -e "${YELLOW}  ⚠ $*${NC}"; }
error()   { echo -e "${RED}  ✗ $*${NC}"; exit 1; }

PLATFORM="${1:-}"
MODE="${2:-release}"

DEFINES_FILE=".dart_defines.json"
DEFINES_FLAG="--dart-define-from-file=$DEFINES_FILE"

# ── Guard checks ──────────────────────────────────────────────────────────────
[ ! -f "pubspec.yaml" ] && error "Run from the ordering app root directory."

if [ ! -f "$DEFINES_FILE" ]; then
  error ".dart_defines.json not found. Run 'bash setup.sh' first, or copy .dart_defines.json.example and fill it in."
fi

# Validate the defines file has real values
API_KEY=$(python3 -c "import json; d=json.load(open('$DEFINES_FILE')); print(d.get('XEBOKI_API_KEY',''))" 2>/dev/null || echo "")
if [ -z "$API_KEY" ] || [ "$API_KEY" = "xbk_live_YOUR_KEY_HERE" ]; then
  error "XEBOKI_API_KEY in $DEFINES_FILE is not set. Run 'bash setup.sh' first."
fi

# ── Usage ─────────────────────────────────────────────────────────────────────
if [ -z "$PLATFORM" ]; then
  echo ""
  echo -e "${BOLD}Usage:${NC}"
  echo "  bash scripts/build.sh android         — debug APK"
  echo "  bash scripts/build.sh android release  — release APK"
  echo "  bash scripts/build.sh android aab      — release AAB (Play Store)"
  echo "  bash scripts/build.sh ios              — release IPA"
  echo "  bash scripts/build.sh ios debug        — debug iOS build"
  echo "  bash scripts/build.sh web              — web build"
  echo ""
  exit 0
fi

# ── Pre-build ─────────────────────────────────────────────────────────────────
info "Running flutter pub get..."
flutter pub get --quiet

info "Running code generator..."
flutter pub run build_runner build --delete-conflicting-outputs --quiet 2>/dev/null || true

# ── Build ─────────────────────────────────────────────────────────────────────
case "$PLATFORM" in

  android)
    case "$MODE" in
      debug)
        info "Building Android debug APK..."
        flutter build apk \
          --debug \
          $DEFINES_FLAG
        OUT="build/app/outputs/flutter-apk/app-debug.apk"
        ;;
      aab)
        info "Building Android release AAB (Play Store)..."
        flutter build appbundle \
          --release \
          $DEFINES_FLAG
        OUT="build/app/outputs/bundle/release/app-release.aab"
        ;;
      release|*)
        info "Building Android release APK..."
        flutter build apk \
          --release \
          --split-per-abi \
          $DEFINES_FLAG
        OUT="build/app/outputs/flutter-apk/"
        ;;
    esac
    ;;

  ios)
    if [[ "$(uname)" != "Darwin" ]]; then
      error "iOS builds require macOS with Xcode installed."
    fi
    case "$MODE" in
      debug)
        info "Building iOS debug..."
        flutter build ios \
          --debug \
          --no-codesign \
          $DEFINES_FLAG
        OUT="build/ios/iphoneos/Runner.app"
        ;;
      release|*)
        info "Building iOS release..."
        flutter build ipa \
          --release \
          $DEFINES_FLAG
        OUT="build/ios/archive/Runner.xcarchive"
        ;;
    esac
    ;;

  web)
    info "Building web release..."
    flutter build web \
      --release \
      $DEFINES_FLAG
    OUT="build/web/"
    ;;

  *)
    error "Unknown platform '$PLATFORM'. Use: android, ios, web"
    ;;
esac

echo ""
success "Build complete!"
info    "Output: $OUT"
echo ""
