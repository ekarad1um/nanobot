#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${1:-$ROOT_DIR/dist/armv7-wheelhouse}"
EXTRAS="${EXTRAS:-}"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is required." >&2
  exit 1
fi

if ! docker buildx version >/dev/null 2>&1; then
  echo "Error: docker buildx is required." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

echo "==> Building ARMv7 (linux/arm/v7) wheelhouse for Python 3.11"
if [ -n "$EXTRAS" ]; then
  echo "==> Including optional extras: $EXTRAS"
fi

docker buildx build \
  --platform linux/arm/v7 \
  --file "$ROOT_DIR/Dockerfile.armv7-py311-wheelhouse" \
  --build-arg "EXTRAS=$EXTRAS" \
  --target export \
  --output "type=local,dest=$OUT_DIR" \
  "$ROOT_DIR"

# buildx local output keeps stage root; wheelhouse will be under $OUT_DIR/wheelhouse
WHEEL_DIR="$OUT_DIR/wheelhouse"
if [ ! -d "$WHEEL_DIR" ]; then
  echo "Error: wheelhouse output not found at $WHEEL_DIR" >&2
  exit 1
fi

TARBALL="$ROOT_DIR/dist/nanobot-armv7-py311-wheelhouse.tar.gz"
mkdir -p "$ROOT_DIR/dist"
tar -C "$OUT_DIR" -czf "$TARBALL" wheelhouse

echo ""
echo "==> Done"
echo "Wheel directory: $WHEEL_DIR"
echo "Packed bundle : $TARBALL"
echo ""
echo "Install on target (offline):"
echo "  python3.11 -m pip install --no-index --find-links \"$WHEEL_DIR\" nanobot-ai"
