#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Generate static DocC docs without adding swift-docc-plugin to this repository's Package.swift.

Usage:
  scripts/generate-docc.sh [options]

Options:
  --target <name>               Target to document (default: SubtitleKit)
  --output <path>               Output directory (default: .build/docc-site)
  --hosting-base-path <path>    Base path for static hosting (default: swift-subtitle-kit)
  --no-hosting-base-path        Omit --hosting-base-path
  --plugin-version <version>    swift-docc-plugin version (default: 1.4.6)
  --open                        Open generated index.html on macOS
  --keep-temp                   Keep temporary working directory
  -h, --help                    Show this help

Examples:
  scripts/generate-docc.sh
  scripts/generate-docc.sh --output docs --hosting-base-path swift-subtitle-kit
  scripts/generate-docc.sh --no-hosting-base-path
USAGE
}

TARGET="SubtitleKit"
OUTPUT=".build/docc-site"
HOSTING_BASE_PATH="swift-subtitle-kit"
USE_HOSTING_BASE_PATH=1
PLUGIN_URL="https://github.com/swiftlang/swift-docc-plugin"
PLUGIN_VERSION="1.4.6"
OPEN_RESULT=0
KEEP_TEMP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    --hosting-base-path)
      HOSTING_BASE_PATH="$2"
      USE_HOSTING_BASE_PATH=1
      shift 2
      ;;
    --no-hosting-base-path)
      USE_HOSTING_BASE_PATH=0
      shift
      ;;
    --plugin-version)
      PLUGIN_VERSION="$2"
      shift 2
      ;;
    --open)
      OPEN_RESULT=1
      shift
      ;;
    --keep-temp)
      KEEP_TEMP=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
  ROOT="$GITHUB_WORKSPACE"
else
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

if [[ "$OUTPUT" = /* ]]; then
  OUTPUT_ABS="$OUTPUT"
else
  OUTPUT_ABS="$ROOT/$OUTPUT"
fi

mkdir -p "$(dirname "$OUTPUT_ABS")"
rm -rf "$OUTPUT_ABS"

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/subtitlekit-docc.XXXXXX")"
cleanup() {
  if [[ "$KEEP_TEMP" -eq 0 ]]; then
    rm -rf "$TMP_DIR"
  else
    echo "Kept temporary directory: $TMP_DIR"
  fi
}
trap cleanup EXIT

echo "Preparing temporary package copy..."
if command -v rsync >/dev/null 2>&1; then
  rsync -a \
    --exclude '.git' \
    --exclude '.build' \
    --exclude 'docs' \
    --exclude '.swiftpm' \
    "$ROOT/" "$TMP_DIR/repo/"
else
  cp -R "$ROOT/." "$TMP_DIR/repo/"
  rm -rf \
    "$TMP_DIR/repo/.git" \
    "$TMP_DIR/repo/.build" \
    "$TMP_DIR/repo/docs" \
    "$TMP_DIR/repo/.swiftpm"
fi

pushd "$TMP_DIR/repo" >/dev/null

echo "Injecting swift-docc-plugin dependency (temporary only)..."
swift package add-dependency "$PLUGIN_URL" --from "$PLUGIN_VERSION" >/dev/null

echo "Generating DocC for target '$TARGET'..."
DOC_CMD=(
  swift package
  --allow-writing-to-directory "$OUTPUT_ABS"
  generate-documentation
  --target "$TARGET"
  --output-path "$OUTPUT_ABS"
  --transform-for-static-hosting
)

if [[ "$USE_HOSTING_BASE_PATH" -eq 1 ]]; then
  DOC_CMD+=(--hosting-base-path "$HOSTING_BASE_PATH")
fi

"${DOC_CMD[@]}"
popd >/dev/null

echo "DocC site generated at: $OUTPUT_ABS"
echo "Entry point: $OUTPUT_ABS/index.html"

if [[ "$OPEN_RESULT" -eq 1 ]]; then
  if command -v open >/dev/null 2>&1; then
    open "$OUTPUT_ABS/index.html"
  else
    echo "'open' command not found; skipping auto-open."
  fi
fi
