#!/usr/bin/env bash
set -euo pipefail

REPO="${DREAMFACTORY_QUICKSTART_REPO:-dreamfactorysoftware/dreamfactory-quickstart}"
VERSION="${DREAMFACTORY_QUICKSTART_VERSION:-latest}"
PLATFORM="${DREAMFACTORY_QUICKSTART_PLATFORM:-linux-x86_64}"
INSTALL_PARENT="${DREAMFACTORY_QUICKSTART_HOME:-$HOME/.local/share}"
INSTALL_DIR="$INSTALL_PARENT/dreamfactory-quickstart"
BIN_DIR="${DREAMFACTORY_QUICKSTART_BIN_DIR:-$HOME/.local/bin}"
ARCHIVE="dreamfactory-quickstart-$PLATFORM.tar.gz"

if [ "$VERSION" = "latest" ]; then
  BASE_URL="https://github.com/$REPO/releases/latest/download"
else
  BASE_URL="https://github.com/$REPO/releases/download/$VERSION"
fi

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64|Linux-amd64)
    ;;
  *)
    echo "DreamFactory Quickstart currently supports Linux x86_64." >&2
    echo "Detected: $(uname -s) $(uname -m)" >&2
    exit 1
    ;;
esac

require_command curl
require_command tar
require_command sha256sum
require_command mktemp

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "Installing DreamFactory Quickstart $VERSION for $PLATFORM"
echo "Download: $BASE_URL/$ARCHIVE"

curl -fL "$BASE_URL/$ARCHIVE" -o "$TMP_DIR/$ARCHIVE"
curl -fL "$BASE_URL/SHA256SUMS" -o "$TMP_DIR/SHA256SUMS"

(
  cd "$TMP_DIR"
  sha256sum -c SHA256SUMS
)

mkdir -p "$INSTALL_PARENT" "$BIN_DIR"
rm -rf "$TMP_DIR/extract"
mkdir -p "$TMP_DIR/extract"
tar xzf "$TMP_DIR/$ARCHIVE" -C "$TMP_DIR/extract"

if [ ! -x "$TMP_DIR/extract/dreamfactory-quickstart/dreamfactory" ]; then
  echo "Downloaded archive did not contain a runnable dreamfactory command." >&2
  exit 1
fi

rm -rf "$INSTALL_DIR"
mv "$TMP_DIR/extract/dreamfactory-quickstart" "$INSTALL_DIR"
cat > "$BIN_DIR/dreamfactory" <<LAUNCHER
#!/usr/bin/env bash
export DF_INSTALL="\${DF_INSTALL:-Quickstart Installer}"
exec "$INSTALL_DIR/dreamfactory" "\$@"
LAUNCHER
chmod +x "$BIN_DIR/dreamfactory"

echo ""
echo "DreamFactory Quickstart installed:"
echo "  $INSTALL_DIR"
echo ""
echo "Command installed:"
echo "  $BIN_DIR/dreamfactory"

case ":$PATH:" in
  *":$BIN_DIR:"*)
    ;;
  *)
    echo ""
    echo "Add this to your shell profile if dreamfactory is not found:"
    echo "  export PATH=\"$BIN_DIR:\$PATH\""
    ;;
esac

echo ""
echo "Start DreamFactory:"
echo "  dreamfactory serve --host 0.0.0.0 --port 8080 --admin-email you@company.example --admin-password YourPassword123456"
