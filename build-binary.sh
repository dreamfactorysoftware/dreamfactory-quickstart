#!/usr/bin/env bash
#
# Build DreamFactory Quickstart as a static binary
#
# Usage:
#   ./build-binary.sh                  Build linux/amd64 binary
#   BRANCH=develop ./build-binary.sh   Build from a specific DF branch
#   VERSION=0.1.0 ./build-binary.sh    Stamp release metadata
#   INCLUDE_MCP=true ./build-binary.sh  Package df-mcp-server and bundled daemon
#   SKIP_DOCKER_BUILD=true ./build-binary.sh  Repackage existing dist binary
#
# Output: ./dist/dreamfactory-linux-x86_64

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$SCRIPT_DIR/dist"
IMAGE_NAME="dreamfactory-quickstart-static"
CONTAINER_NAME="dreamfactory-quickstart-static-tmp"
BINARY_SRC="/go/src/app/dist/frankenphp-linux-x86_64"
ODBC_SRC="/go/src/app/dist/odbc-runtime"
MCP_DAEMON_SRC="/go/src/app/dist/mcp-daemon"
NODE_RUNTIME_SRC="/go/src/app/dist/node-runtime"
BINARY_DST="$DIST_DIR/dreamfactory-linux-x86_64"
LOCAL_PACKAGES_DIR="$SCRIPT_DIR/.build/local-packages"

BRANCH="${BRANCH:-master}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
VERSION="${VERSION:-0.1.0-dev}"
PLATFORM="${PLATFORM:-linux-x86_64}"
SKIP_DOCKER_BUILD="${SKIP_DOCKER_BUILD:-false}"
INCLUDE_MCP="${INCLUDE_MCP:-false}"
MCP_PACKAGE_DIR="${MCP_PACKAGE_DIR:-$SCRIPT_DIR/../dreamfactory-dev/dreamfactory-development-packages/df-mcp-server}"
INCLUDE_LOCAL_PACKAGES="${INCLUDE_LOCAL_PACKAGES:-true}"
LOCAL_DF_SYSTEM_DIR="${LOCAL_DF_SYSTEM_DIR:-$SCRIPT_DIR/../dreamfactory-dev/dreamfactory-development-packages/df-system}"
LOCAL_DF_ADMIN_INTERFACE_DIR="${LOCAL_DF_ADMIN_INTERFACE_DIR:-$SCRIPT_DIR/../dreamfactory-dev/dreamfactory-development-packages/df-admin-interface}"
BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
GIT_COMMIT="$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || printf 'unknown')"

echo "============================================"
echo "  Building DreamFactory Quickstart Binary"
echo "  Branch: $BRANCH"
echo "  Version: $VERSION"
echo "  Platform: $PLATFORM"
echo "  Include MCP: $INCLUDE_MCP"
echo "  Include local packages: $INCLUDE_LOCAL_PACKAGES"
echo "  Skip Docker build: $SKIP_DOCKER_BUILD"
echo "============================================"
echo ""

mkdir -p "$DIST_DIR"
rm -rf "$SCRIPT_DIR/.build/df-mcp-server"
mkdir -p "$SCRIPT_DIR/.build/df-mcp-server"
rm -rf "$LOCAL_PACKAGES_DIR"
mkdir -p "$LOCAL_PACKAGES_DIR"

copy_local_package() {
  local source_dir="$1"
  local target_name="$2"

  if [ ! -f "$source_dir/composer.json" ]; then
    return 0
  fi

  echo "Preparing local package $target_name from $source_dir"
  mkdir -p "$LOCAL_PACKAGES_DIR/$target_name"
  tar \
    --exclude='.git' \
    --exclude='.angular' \
    --exclude='.cache' \
    --exclude='coverage' \
    --exclude='node_modules' \
    --exclude='test-results' \
    --exclude='vendor' \
    -C "$source_dir" \
    -cf - . | tar -C "$LOCAL_PACKAGES_DIR/$target_name" -xf -
}

if [ "$INCLUDE_LOCAL_PACKAGES" = "true" ]; then
  copy_local_package "$LOCAL_DF_SYSTEM_DIR" "df-system"
  copy_local_package "$LOCAL_DF_ADMIN_INTERFACE_DIR" "df-admin-interface"
fi

if [ "$INCLUDE_MCP" = "true" ]; then
  if [ ! -f "$MCP_PACKAGE_DIR/composer.json" ] || [ ! -f "$MCP_PACKAGE_DIR/daemon/package.json" ]; then
    echo "MCP package not found at $MCP_PACKAGE_DIR" >&2
    echo "Set MCP_PACKAGE_DIR=/path/to/df-mcp-server or run with INCLUDE_MCP=false." >&2
    exit 1
  fi
  echo "Preparing MCP package from $MCP_PACKAGE_DIR"
  tar \
    --exclude='.git' \
    --exclude='daemon/node_modules' \
    --exclude='vendor' \
    -C "$MCP_PACKAGE_DIR" \
    -cf - . | tar -C "$SCRIPT_DIR/.build/df-mcp-server" -xf -
fi

# Build args
BUILD_ARGS="--build-arg BRANCH=$BRANCH --build-arg INCLUDE_MCP=$INCLUDE_MCP"
SECRET_ARGS=()
if [ -n "$GITHUB_TOKEN" ]; then
  SECRET_ARGS=(--secret id=github_token,env=GITHUB_TOKEN)
fi

if [ "$SKIP_DOCKER_BUILD" = "true" ]; then
  echo "[1/3] Reusing existing static binary..."
  if [ ! -x "$BINARY_DST" ]; then
    echo "Missing existing binary: $BINARY_DST" >&2
    exit 1
  fi
  if [ ! -d "$DIST_DIR/odbc-runtime" ]; then
    echo "Missing existing ODBC runtime: $DIST_DIR/odbc-runtime" >&2
    exit 1
  fi
  if [ "$INCLUDE_MCP" = "true" ]; then
    if [ ! -d "$DIST_DIR/mcp-daemon" ] || [ ! -x "$DIST_DIR/node-runtime/bin/node" ]; then
      echo "Missing existing MCP daemon or Node runtime in dist/. Rebuild without SKIP_DOCKER_BUILD first." >&2
      exit 1
    fi
  fi
else
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
  rm -rf "$DIST_DIR/mcp-daemon" "$DIST_DIR/node-runtime"
  docker cp "$CONTAINER_ID:$MCP_DAEMON_SRC" "$DIST_DIR/mcp-daemon"
  docker cp "$CONTAINER_ID:$NODE_RUNTIME_SRC" "$DIST_DIR/node-runtime"
  docker rm "$CONTAINER_NAME"
fi

chmod +x "$BINARY_DST"

echo "Verifying extracted binary..."
"$BINARY_DST" version >/dev/null

echo ""
echo "[3/3] Packaging distribution..."

# Create the distribution tarball
TARBALL="$DIST_DIR/dreamfactory-quickstart-$PLATFORM.tar.gz"
CHECKSUMS="$DIST_DIR/SHA256SUMS"
STAGING="$DIST_DIR/dreamfactory-quickstart"
rm -rf "$STAGING"
mkdir -p "$STAGING"

# Rename binary and include wrapper
cp "$BINARY_DST" "$STAGING/frankenphp"
cp "$SCRIPT_DIR/bin/dreamfactory-ctl" "$STAGING/dreamfactory"
cp -a "$DIST_DIR/odbc-runtime" "$STAGING/odbc"
if [ "$INCLUDE_MCP" = "true" ]; then
  cp -a "$DIST_DIR/mcp-daemon" "$STAGING/mcp-daemon"
  cp -a "$DIST_DIR/node-runtime" "$STAGING/node"
fi
chmod +x "$STAGING/dreamfactory" "$STAGING/frankenphp"
[ "$INCLUDE_MCP" != "true" ] || chmod +x "$STAGING/node/bin/node"

printf '%s\n' "$VERSION" > "$STAGING/VERSION"
cat > "$STAGING/release.json" <<JSON
{
  "name": "dreamfactory-quickstart",
  "version": "$VERSION",
  "platform": "$PLATFORM",
  "dreamfactory_branch": "$BRANCH",
  "quickstart_commit": "$GIT_COMMIT",
  "build_date": "$BUILD_DATE",
  "mcp_enabled": $([ "$INCLUDE_MCP" = "true" ] && printf true || printf false),
  "entrypoint": "./dreamfactory serve",
  "storage_env": "DREAMFACTORY_STORAGE",
  "default_storage": "~/.dreamfactory"
}
JSON

echo "Verifying packaged wrapper..."
"$STAGING/dreamfactory" help >/dev/null
DREAMFACTORY_STORAGE="$DIST_DIR/.smoke-storage" "$STAGING/dreamfactory" artisan --version >/dev/null
rm -rf "$DIST_DIR/.smoke-storage"

tar -czf "$TARBALL" -C "$DIST_DIR" dreamfactory-quickstart/
(
  cd "$DIST_DIR"
  sha256sum "$(basename "$TARBALL")" > "$CHECKSUMS"
)

SIZE=$(du -sh "$BINARY_DST" | cut -f1)
TAR_SIZE=$(du -sh "$TARBALL" | cut -f1)

echo ""
echo "============================================"
echo "  Build complete!"
echo ""
echo "  Binary:  $BINARY_DST ($SIZE)"
echo "  Tarball: $TARBALL ($TAR_SIZE)"
echo "  SHA256:  $CHECKSUMS"
echo ""
echo "  Quick start:"
echo "    tar xzf $TARBALL"
echo "    cd dreamfactory-quickstart"
echo "    ADMIN_EMAIL=you@company.example ADMIN_PASSWORD=YourPassword123456 ./dreamfactory serve"
echo "============================================"
