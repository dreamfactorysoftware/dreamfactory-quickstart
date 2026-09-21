#!/usr/bin/env bash
#
# Build DreamFactory Quickstart as a macOS FrankenPHP binary.
#
# This is the macOS preview path. It mirrors build-binary.sh, but runs natively
# because FrankenPHP's Linux static-builder Docker image cannot emit Darwin
# binaries.
#
# Usage:
#   ./build-macos.sh
#   VERSION=0.1.5-macos INCLUDE_MCP=true ./build-macos.sh
#
# Output: ./dist/dreamfactory-quickstart-darwin-arm64.tar.gz

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$SCRIPT_DIR/dist"
BUILD_DIR="$SCRIPT_DIR/.build/macos"
LOCAL_PACKAGES_DIR="$SCRIPT_DIR/.build/local-packages"

BRANCH="${BRANCH:-master}"
VERSION="${VERSION:-0.1.0-dev}"
INCLUDE_MCP="${INCLUDE_MCP:-true}"
INCLUDE_LOCAL_PACKAGES="${INCLUDE_LOCAL_PACKAGES:-true}"
MCP_PACKAGE_DIR="${MCP_PACKAGE_DIR:-$SCRIPT_DIR/../dreamfactory-dev/dreamfactory-development-packages/df-mcp-server}"
LOCAL_DF_SYSTEM_DIR="${LOCAL_DF_SYSTEM_DIR:-$SCRIPT_DIR/../dreamfactory-dev/dreamfactory-development-packages/df-system}"
LOCAL_DF_ADMIN_INTERFACE_DIR="${LOCAL_DF_ADMIN_INTERFACE_DIR:-$SCRIPT_DIR/../dreamfactory-dev/dreamfactory-development-packages/df-admin-interface}"
NODE_VERSION="${NODE_VERSION:-20.19.0}"
BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
GIT_COMMIT="$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || printf 'unknown')"

case "$(uname -s)-$(uname -m)" in
  Darwin-arm64|Darwin-aarch64)
    PLATFORM="darwin-arm64"
    NODE_PLATFORM="darwin-arm64"
    ;;
  Darwin-x86_64|Darwin-amd64)
    PLATFORM="darwin-x86_64"
    NODE_PLATFORM="darwin-x64"
    ;;
  *)
    echo "build-macos.sh must run on macOS arm64 or x86_64." >&2
    echo "Detected: $(uname -s) $(uname -m)" >&2
    exit 1
    ;;
esac

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

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

patch_composer_for_quickstart() {
  local app_dir="$1"

  php -r '
    $file = $argv[1];
    $includeMcp = $argv[2] === "true";
    $json = json_decode(file_get_contents($file), true);
    if (!isset($json["repositories"])) {
      $json["repositories"] = [];
    }
    if ($includeMcp) {
      $json["repositories"][] = ["type" => "path", "url" => "/tmp/df-mcp-server", "options" => ["symlink" => false]];
      $json["require"]["dreamfactory/df-mcp-server"] = "*";
    }
    $versions = ["dreamfactory/df-system" => "0.6.4", "dreamfactory/df-admin-interface" => "1.7.4"];
    foreach (["df-system", "df-admin-interface"] as $package) {
      $path = dirname($file) . "/../local-packages/" . $package;
      if (is_file($path . "/composer.json")) {
        $packageJson = json_decode(file_get_contents($path . "/composer.json"), true);
        $name = $packageJson["name"];
        array_unshift($json["repositories"], ["type" => "path", "url" => $path, "options" => ["symlink" => false, "versions" => [$name => $versions[$name] ?? "999.999.999"]]]);
        $json["require"][$name] = "*";
      }
    }
    file_put_contents($file, json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL);
  ' "$app_dir/composer.json" "$INCLUDE_MCP"
}

require_command curl
require_command git
require_command php
require_command composer
require_command npm
require_command tar
require_command shasum

echo "============================================"
echo "  Building DreamFactory Quickstart macOS"
echo "  Branch: $BRANCH"
echo "  Version: $VERSION"
echo "  Platform: $PLATFORM"
echo "  Include MCP: $INCLUDE_MCP"
echo "  Include local packages: $INCLUDE_LOCAL_PACKAGES"
echo "============================================"
echo ""

mkdir -p "$DIST_DIR"
rm -rf "$BUILD_DIR" "$LOCAL_PACKAGES_DIR"
mkdir -p "$BUILD_DIR" "$LOCAL_PACKAGES_DIR"

if [ "$INCLUDE_LOCAL_PACKAGES" = "true" ]; then
  copy_local_package "$LOCAL_DF_SYSTEM_DIR" "df-system"
  copy_local_package "$LOCAL_DF_ADMIN_INTERFACE_DIR" "df-admin-interface"
fi
cp -R "$LOCAL_PACKAGES_DIR" "$BUILD_DIR/local-packages"

if [ "$INCLUDE_MCP" = "true" ]; then
  if [ ! -f "$MCP_PACKAGE_DIR/composer.json" ] || [ ! -f "$MCP_PACKAGE_DIR/daemon/package.json" ]; then
    echo "MCP package not found at $MCP_PACKAGE_DIR" >&2
    echo "Set MCP_PACKAGE_DIR=/path/to/df-mcp-server or run with INCLUDE_MCP=false." >&2
    exit 1
  fi
  mkdir -p "$BUILD_DIR/df-mcp-server"
  tar \
    --exclude='.git' \
    --exclude='daemon/node_modules' \
    --exclude='vendor' \
    -C "$MCP_PACKAGE_DIR" \
    -cf - . | tar -C "$BUILD_DIR/df-mcp-server" -xf -
fi

echo "[1/4] Preparing DreamFactory application"
git clone --depth 1 --branch "$BRANCH" \
  https://github.com/dreamfactorysoftware/dreamfactory.git "$BUILD_DIR/app"
rm -rf "$BUILD_DIR/app/.git"
cp "$SCRIPT_DIR/composer.binary.json" "$BUILD_DIR/app/composer.json"
patch_composer_for_quickstart "$BUILD_DIR/app"

if [ "$INCLUDE_MCP" = "true" ]; then
  rm -rf /tmp/df-mcp-server
  cp -R "$BUILD_DIR/df-mcp-server" /tmp/df-mcp-server
fi

(
  cd "$BUILD_DIR/app"
  rm -f composer.lock bootstrap/cache/packages.php bootstrap/cache/services.php
  php -r '$file="config/app.php"; $text=file_get_contents($file); $text=preg_replace("/^.*MongoDB.*MongoDBServiceProvider.*\n/m", "", $text); $text=preg_replace("/^.*Add MongoDB Provider.*\n/m", "", $text); file_put_contents($file, $text);'
  COMPOSER_MEMORY_LIMIT=-1 composer update --no-dev --ignore-platform-reqs --no-scripts
  php -r '$file="vendor/dreamfactory/df-core/src/LaravelServiceProvider.php"; $text=file_get_contents($file); $text=preg_replace("/^.*use MongoDB.*\n/m", "", $text); $text=preg_replace("/^.*MongoDBServiceProvider.*\n/m", "", $text); file_put_contents($file, $text);'
  composer dump-autoload --optimize
  php artisan package:discover --ansi
  cp .env-dist .env
  php -r '$file=".env"; $text=file_get_contents($file); $replacements=["APP_ENV"=>"production","APP_DEBUG"=>"false","DB_CONNECTION"=>"sqlite","CACHE_DRIVER"=>"file","DF_INSTALL"=>"\"binary quickstart\""]; foreach($replacements as $key=>$value){ $text=preg_replace("/^".$key."=.*/m", $key."=".$value, $text); } file_put_contents($file, $text);'
  mkdir -p storage/app storage/databases storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache
  rm -rf tests .git .github .docker docker-compose* Dockerfile*
  find vendor -type d \( -name "tests" -o -name "test" -o -name "Tests" -o -name "docs" -o -name ".git" \) -prune -exec rm -rf {} + 2>/dev/null || true
)

mkdir -p "$BUILD_DIR/mcp-daemon"
if [ "$INCLUDE_MCP" = "true" ]; then
  echo "[2/4] Building MCP daemon"
  (
    cd "$BUILD_DIR/df-mcp-server/daemon"
    npm ci
    npm run build
    npm prune --omit=dev
  )
  cp "$BUILD_DIR/df-mcp-server/daemon/package.json" "$BUILD_DIR/df-mcp-server/daemon/package-lock.json" "$BUILD_DIR/mcp-daemon/"
  cp -a "$BUILD_DIR/df-mcp-server/daemon/dist" "$BUILD_DIR/df-mcp-server/daemon/node_modules" "$BUILD_DIR/mcp-daemon/"
fi

echo "[3/4] Building FrankenPHP for $PLATFORM"
git clone --depth 1 https://github.com/php/frankenphp.git "$BUILD_DIR/frankenphp"
(
  cd "$BUILD_DIR/frankenphp"
  export PHP_VERSION=8.4
  export PHP_EXTENSIONS="bcmath,ctype,curl,dom,fileinfo,filter,mbstring,mbregex,opcache,openssl,pdo_mysql,pdo_pgsql,pdo_sqlite,phar,session,simplexml,soap,tokenizer,xml,xmlreader,xmlwriter"
  export PHP_EXTENSION_LIBS="libavif,nghttp2,nghttp3,ngtcp2,watcher,libssh2,zstd,onig"
  export EMBED="$BUILD_DIR/app/"
  export NO_COMPRESS=1
  ./build-static.sh || test -x dist/static-php-cli/buildroot/bin/frankenphp
)

FRANKENPHP_BIN="$(find "$BUILD_DIR/frankenphp/dist" "$BUILD_DIR/frankenphp/dist/static-php-cli/buildroot/bin" -type f -name 'frankenphp*' -perm -111 2>/dev/null | sort | tail -1 || true)"
if [ -z "$FRANKENPHP_BIN" ]; then
  FRANKENPHP_BIN="$(find "$BUILD_DIR/frankenphp/dist" "$BUILD_DIR/frankenphp/dist/static-php-cli/buildroot/bin" -type f -name 'frankenphp*' 2>/dev/null | sort | tail -1 || true)"
fi
if [ -z "$FRANKENPHP_BIN" ]; then
  echo "Could not locate built FrankenPHP binary." >&2
  exit 1
fi

echo "[4/4] Packaging distribution"
STAGING="$DIST_DIR/dreamfactory-quickstart"
TARBALL="$DIST_DIR/dreamfactory-quickstart-$PLATFORM.tar.gz"
CHECKSUMS="$DIST_DIR/SHA256SUMS"
rm -rf "$STAGING"
mkdir -p "$STAGING"

cp "$FRANKENPHP_BIN" "$STAGING/frankenphp"
cp "$SCRIPT_DIR/bin/dreamfactory-ctl" "$STAGING/dreamfactory"
chmod +x "$STAGING/frankenphp" "$STAGING/dreamfactory"

if [ "$INCLUDE_MCP" = "true" ]; then
  cp -a "$BUILD_DIR/mcp-daemon" "$STAGING/mcp-daemon"
  NODE_ARCHIVE="node-v$NODE_VERSION-$NODE_PLATFORM.tar.gz"
  NODE_URL="https://nodejs.org/dist/v$NODE_VERSION/$NODE_ARCHIVE"
  curl -fL "$NODE_URL" -o "$BUILD_DIR/$NODE_ARCHIVE"
  mkdir -p "$STAGING/node"
  tar xzf "$BUILD_DIR/$NODE_ARCHIVE" -C "$STAGING/node" --strip-components=1
  chmod +x "$STAGING/node/bin/node"
fi

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
  "default_storage": "~/.dreamfactory",
  "preview_notes": "macOS preview build; SQL Server ODBC bundle is not included yet"
}
JSON

"$STAGING/frankenphp" version >/dev/null
DREAMFACTORY_STORAGE="$DIST_DIR/.smoke-storage" "$STAGING/dreamfactory" artisan --version >/dev/null
rm -rf "$DIST_DIR/.smoke-storage"

tar -czf "$TARBALL" -C "$DIST_DIR" dreamfactory-quickstart/
(
  cd "$DIST_DIR"
  shasum -a 256 "$(basename "$TARBALL")" > "$CHECKSUMS"
)

echo ""
echo "macOS build complete:"
echo "  Tarball: $TARBALL"
echo "  SHA256:  $CHECKSUMS"
