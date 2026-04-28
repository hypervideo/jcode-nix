#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_NIX="$REPO_DIR/default.nix"

OWNER="1jehuang"
REPO="jcode"

CURRENT_VERSION=$(grep 'version = "' "$DEFAULT_NIX" | head -1 | sed 's/.*version = "\(.*\)";/\1/')
echo "Current version: $CURRENT_VERSION"

RELEASE_JSON=$(curl -sfL "https://api.github.com/repos/$OWNER/$REPO/releases/latest")
LATEST_TAG=$(jq -r '.tag_name' <<<"$RELEASE_JSON")
if [ -z "$LATEST_TAG" ] || [ "$LATEST_TAG" = "null" ]; then
  echo "Could not determine latest GitHub release tag." >&2
  exit 1
fi

LATEST_VERSION="${LATEST_TAG#v}"
echo "Latest GitHub release: $LATEST_TAG"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
  echo "Already up to date."
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "UPDATED=false" >> "$GITHUB_OUTPUT"
  fi
  exit 0
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Resolving source hash..."
SOURCE_URL="https://github.com/$OWNER/$REPO/archive/refs/tags/$LATEST_TAG.tar.gz"
SRC_HASH=$(nix store prefetch-file --json --unpack "$SOURCE_URL" | jq -r .hash)

echo "Resolving release commit metadata..."
git clone --depth 1 --branch "$LATEST_TAG" "https://github.com/$OWNER/$REPO.git" "$WORK_DIR/source" >/dev/null 2>&1
BUILD_COMMIT=$(git -C "$WORK_DIR/source" rev-parse HEAD)
BUILD_GIT_DATE=$(git -C "$WORK_DIR/source" log -1 --format=%ci)

echo "Updating default.nix to $LATEST_VERSION..."
awk \
  -v version="$LATEST_VERSION" \
  -v srcHash="$SRC_HASH" \
  -v buildCommit="$BUILD_COMMIT" \
  -v buildGitDate="$BUILD_GIT_DATE" \
  '
    /version = "/ {
      sub(/version = "[^"]+"/, "version = \"" version "\"")
    }
    /srcHash = "/ {
      sub(/srcHash = "[^"]+"/, "srcHash = \"" srcHash "\"")
    }
    /buildCommit = "/ {
      sub(/buildCommit = "[^"]+"/, "buildCommit = \"" buildCommit "\"")
    }
    /buildGitDate = "/ {
      sub(/buildGitDate = "[^"]+"/, "buildGitDate = \"" buildGitDate "\"")
    }
    /cargoHash = / {
      sub(/cargoHash = .*/, "cargoHash = lib.fakeHash;")
    }
    { print }
  ' "$DEFAULT_NIX" > "$DEFAULT_NIX.tmp"
mv "$DEFAULT_NIX.tmp" "$DEFAULT_NIX"

echo "Resolving Cargo vendor hash..."
BUILD_LOG="$WORK_DIR/nix-build.log"
set +e
nix build "$REPO_DIR#default" 2>"$BUILD_LOG"
BUILD_STATUS=$?
set -e

if [ "$BUILD_STATUS" -eq 0 ]; then
  echo "nix build unexpectedly succeeded with lib.fakeHash; leaving cargoHash unchanged." >&2
  exit 1
fi

CARGO_HASH=$(sed -nE 's/.*got:[[:space:]]*(sha256-[A-Za-z0-9+\/=]+).*/\1/p' "$BUILD_LOG" | tail -1)
if [ -z "$CARGO_HASH" ]; then
  echo "Could not determine Cargo vendor hash from nix build output." >&2
  cat "$BUILD_LOG" >&2
  exit 1
fi

awk -v cargoHash="$CARGO_HASH" '
  /cargoHash = / {
    sub(/cargoHash = .*/, "cargoHash = \"" cargoHash "\";")
  }
  { print }
' "$DEFAULT_NIX" > "$DEFAULT_NIX.tmp"
mv "$DEFAULT_NIX.tmp" "$DEFAULT_NIX"

echo "Updated $REPO to $LATEST_VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "VERSION=$LATEST_VERSION" >> "$GITHUB_OUTPUT"
  echo "UPDATED=true" >> "$GITHUB_OUTPUT"
fi
