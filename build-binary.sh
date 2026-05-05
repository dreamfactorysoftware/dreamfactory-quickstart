#!/usr/bin/env bash
#
# Build DreamFactory Quickstart as a static binary
#
# Usage:
#   ./build-binary.sh                  Build linux/amd64 binary
#   BRANCH=develop ./build-binary.sh   Build from a specific DF branch
#
# Output: ./dist/dreamfactory-linux-x86_64

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$SCRIPT_DIR/dist"
IMAGE_NAME="dreamfactory-quickstart-static"
CONTAINER_NAME="dreamfactory-quickstart-static-tmp"
BINARY_SRC="/go/src/app/dist/frankenphp-linux-x86_64"
ODBC_SRC="/go/src/app/dist/odbc-runtime"
BINARY_DST="$DIST_DIR/dreamfactory-linux-x86_64"

BRANCH="${BRANCH:-master}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

echo "============================================"
echo "  Building DreamFactory Quickstart Binary"
echo "  Branch: $BRANCH"
echo "============================================"
echo ""

mkdir -p "$DIST_DIR"

# Build args
BUILD_ARGS="--build-arg BRANCH=$BRANCH"
SECRET_ARGS=()
if [ -n "$GITHUB_TOKEN" ]; then
  SECRET_ARGS=(--secret id=github_token,env=GITHUB_TOKEN)
fi

echo "[1/3] Building static binary (this takes a while)..."
docker build \
  $BUILD_ARGS \
  "${SECRET_ARGS[@]}" \
  -t "$IMAGE_NAME" \
  -f static-build.Dockerfile \
  "$SCRIPT_DIR"

echo ""
echo "[2/3] Extracting binary..."
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
CONTAINER_ID="$(docker create --name "$CONTAINER_NAME" "$IMAGE_NAME")"
docker cp "$CONTAINER_ID:$BINARY_SRC" "$BINARY_DST"
rm -rf "$DIST_DIR/odbc-runtime"
docker cp "$CONTAINER_ID:$ODBC_SRC" "$DIST_DIR/odbc-runtime"
docker rm "$CONTAINER_NAME"

chmod +x "$BINARY_DST"

echo "Verifying extracted binary..."
"$BINARY_DST" version >/dev/null

echo ""
echo "[3/3] Packaging distribution..."

# Create the distribution tarball
TARBALL="$DIST_DIR/dreamfactory-quickstart-linux-x86_64.tar.gz"
STAGING="$DIST_DIR/dreamfactory-quickstart"
rm -rf "$STAGING"
mkdir -p "$STAGING"

# Rename binary and include wrapper
cp "$BINARY_DST" "$STAGING/frankenphp"
cp "$SCRIPT_DIR/bin/dreamfactory-ctl" "$STAGING/dreamfactory"
cp -a "$DIST_DIR/odbc-runtime" "$STAGING/odbc"
chmod +x "$STAGING/dreamfactory" "$STAGING/frankenphp"

echo "Verifying packaged wrapper..."
"$STAGING/dreamfactory" help >/dev/null
DREAMFACTORY_STORAGE="$DIST_DIR/.smoke-storage" "$STAGING/dreamfactory" artisan --version >/dev/null
rm -rf "$DIST_DIR/.smoke-storage"

tar -czf "$TARBALL" -C "$DIST_DIR" dreamfactory-quickstart/

SIZE=$(du -sh "$BINARY_DST" | cut -f1)
TAR_SIZE=$(du -sh "$TARBALL" | cut -f1)

echo ""
echo "============================================"
echo "  Build complete!"
echo ""
echo "  Binary:  $BINARY_DST ($SIZE)"
echo "  Tarball: $TARBALL ($TAR_SIZE)"
echo ""
echo "  Quick start:"
echo "    tar xzf $TARBALL"
echo "    cd dreamfactory-quickstart"
echo "    ADMIN_EMAIL=you@company.example ADMIN_PASSWORD=YourPassword123456 ./dreamfactory serve"
echo "============================================"
