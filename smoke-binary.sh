#!/usr/bin/env bash
#
# Internal smoke test for a packaged DreamFactory Quickstart binary.
#
# Usage:
#   ./smoke-binary.sh
#   ./smoke-binary.sh dist/dreamfactory-quickstart-linux-x86_64.tar.gz
#   ./smoke-binary.sh dist/dreamfactory-quickstart

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-$ROOT_DIR/dist/dreamfactory-quickstart}"
PORT="${PORT:-18088}"
TMP_DIR="$(mktemp -d)"
SERVER_PID=""

cleanup() {
  if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd curl

case "$TARGET" in
  *.tar.gz|*.tgz)
    tar -xzf "$TARGET" -C "$TMP_DIR"
    APP_DIR="$TMP_DIR/dreamfactory-quickstart"
    ;;
  *)
    APP_DIR="$TARGET"
    ;;
esac

DREAMFACTORY="$APP_DIR/dreamfactory"
FRANKENPHP="$APP_DIR/frankenphp"
STORAGE="$TMP_DIR/storage"
LOG="$TMP_DIR/server.log"

if [ ! -x "$DREAMFACTORY" ] || [ ! -x "$FRANKENPHP" ]; then
  echo "Expected executable dreamfactory and frankenphp files in $APP_DIR" >&2
  exit 1
fi

echo "[1/5] Checking binary metadata"
"$FRANKENPHP" version

echo "[2/5] Checking embedded Laravel app"
DREAMFACTORY_STORAGE="$STORAGE" "$DREAMFACTORY" artisan --version
DREAMFACTORY_STORAGE="$STORAGE" "$DREAMFACTORY" ai spec >/dev/null

echo "[3/5] Starting server on port $PORT"
SMOKE_ADMIN_EMAIL="${ADMIN_EMAIL:-admin@dreamfactory.com}"
SMOKE_ADMIN_PASSWORD="${ADMIN_PASSWORD:-YourPassword123456}"

ADMIN_EMAIL="$SMOKE_ADMIN_EMAIL" \
ADMIN_PASSWORD="$SMOKE_ADMIN_PASSWORD" \
DREAMFACTORY_STORAGE="$STORAGE" \
SERVER_PORT="$PORT" \
"$DREAMFACTORY" serve >"$LOG" 2>&1 &
SERVER_PID="$!"

echo "[4/5] Waiting for HTTP response"
for _ in $(seq 1 90); do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Server exited early. Last log lines:" >&2
    tail -80 "$LOG" >&2 || true
    exit 1
  fi

  api_status="$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$PORT/api/v2" || true)"
  root_status="$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$PORT/" || true)"
  admin_status="$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$PORT/dreamfactory/dist/index.html" || true)"
  case "$api_status" in
    200|401|403|404)
      login_status="$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "http://127.0.0.1:$PORT/api/v2/system/admin/session" \
        --data-urlencode "email=$SMOKE_ADMIN_EMAIL" \
        --data-urlencode "password=$SMOKE_ADMIN_PASSWORD" || true)"
      if [ "$root_status" = "302" ] && [ "$admin_status" = "200" ] && [ "$login_status" = "200" ]; then
        echo "[5/5] Checking doctor and AI login"
        DREAMFACTORY_STORAGE="$STORAGE" "$DREAMFACTORY" doctor
        "$DREAMFACTORY" ai login \
          --url "http://127.0.0.1:$PORT/api/v2" \
          --email "$SMOKE_ADMIN_EMAIL" \
          --password "$SMOKE_ADMIN_PASSWORD" >/dev/null
        echo "Smoke test passed: root redirects, admin UI loads, API responds, and admin login succeeds"
        exit 0
      fi
      ;;
  esac

  sleep 1
done

echo "Timed out waiting for server. Last log lines:" >&2
tail -120 "$LOG" >&2 || true
exit 1
