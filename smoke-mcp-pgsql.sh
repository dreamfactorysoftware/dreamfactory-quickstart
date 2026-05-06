#!/usr/bin/env bash
#
# End-to-end MCP smoke test for a packaged DreamFactory Quickstart artifact.
#
# This verifies the product path that matters for AI data access:
# packaged binary -> DreamFactory API -> PostgreSQL service -> MCP tool call.
#
# Usage:
#   ./smoke-mcp-pgsql.sh dist/dreamfactory-quickstart-linux-x86_64.tar.gz
#   ./smoke-mcp-pgsql.sh dist/dreamfactory-quickstart

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-$ROOT_DIR/dist/dreamfactory-quickstart-linux-x86_64.tar.gz}"
DF_PORT="${MCP_SMOKE_DF_PORT:-18140}"
MCP_PORT="${MCP_SMOKE_MCP_PORT:-18146}"
PG_PORT="${MCP_SMOKE_PG_PORT:-15446}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-YourPassword123456}"
PG_NAME="df-mcp-pg-test-$$"
TMP_DIR="$(mktemp -d)"
SERVER_PID=""

cleanup() {
  if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  docker rm -f "$PG_NAME" >/dev/null 2>&1 || true
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
require_cmd docker
require_cmd jq

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
STORAGE="$TMP_DIR/storage"
LOG="$TMP_DIR/server.log"

if [ ! -x "$DREAMFACTORY" ]; then
  echo "Expected executable dreamfactory file in $APP_DIR" >&2
  exit 1
fi

if [ ! -d "$APP_DIR/mcp-daemon" ]; then
  echo "Expected MCP-enabled artifact with mcp-daemon/ in $APP_DIR" >&2
  exit 1
fi

echo "[1/7] Starting PostgreSQL fixture"
docker run -d --rm \
  --name "$PG_NAME" \
  -e POSTGRES_PASSWORD=dfpass \
  -e POSTGRES_USER=dfuser \
  -e POSTGRES_DB=dfdemo \
  -p "$PG_PORT:5432" \
  postgres:16-alpine >/dev/null

for i in $(seq 1 90); do
  if docker exec "$PG_NAME" psql -U dfuser -d dfdemo -tAc 'select 1' >/dev/null 2>&1; then
    break
  fi
  if [ "$i" = 90 ]; then
    docker logs "$PG_NAME" >&2 || true
    exit 1
  fi
  sleep 1
done

docker exec -i "$PG_NAME" psql -U dfuser -d dfdemo >/dev/null <<'SQL'
CREATE TABLE customers (
  id serial PRIMARY KEY,
  name text NOT NULL,
  tier text NOT NULL,
  balance numeric(10,2) NOT NULL DEFAULT 0
);
INSERT INTO customers (name, tier, balance) VALUES
  ('Acme Analytics', 'gold', 1250.50),
  ('Blue Mesa Co', 'silver', 410.00);
SQL

echo "[2/7] Starting packaged DreamFactory with MCP"
ADMIN_EMAIL="$ADMIN_EMAIL" \
ADMIN_PASSWORD="$ADMIN_PASSWORD" \
DREAMFACTORY_STORAGE="$STORAGE" \
"$DREAMFACTORY" serve --with-mcp --port "$DF_PORT" --mcp-port "$MCP_PORT" >"$LOG" 2>&1 &
SERVER_PID="$!"

for i in $(seq 1 120); do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "DreamFactory exited early. Last log lines:" >&2
    tail -120 "$LOG" >&2 || true
    exit 1
  fi
  login_status="$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "http://127.0.0.1:$DF_PORT/api/v2/system/admin/session" \
    --data-urlencode "email=$ADMIN_EMAIL" \
    --data-urlencode "password=$ADMIN_PASSWORD" || true)"
  if [ "$login_status" = 200 ] && curl -fsS "http://127.0.0.1:$MCP_PORT/health" >/dev/null 2>&1; then
    break
  fi
  if [ "$i" = 120 ]; then
    echo "Timed out waiting for DreamFactory/MCP. Last log lines:" >&2
    tail -120 "$LOG" >&2 || true
    exit 1
  fi
  sleep 1
done

echo "[3/7] Logging in"
TOKEN="$("$DREAMFACTORY" login \
  --url "http://127.0.0.1:$DF_PORT/api/v2" \
  --email "$ADMIN_EMAIL" \
  --password "$ADMIN_PASSWORD" \
  --token-only)"

if [ -z "$TOKEN" ]; then
  echo "Could not obtain DreamFactory session token" >&2
  exit 1
fi

echo "[4/7] Running PostgreSQL quickstart"
QUICKSTART_JSON="$("$DREAMFACTORY" quickstart pgsql \
  --url "http://127.0.0.1:$DF_PORT/api/v2" \
  --session-token "$TOKEN" \
  --name demo_pgsql \
  --label "MCP PostgreSQL Demo" \
  --db-host 127.0.0.1 \
  --db-port "$PG_PORT" \
  --db-name dfdemo \
  --db-user dfuser \
  --db-password dfpass)"
printf '%s' "$QUICKSTART_JSON" | jq -e '.status == "ready" and .verified.table_list == true' >/dev/null
printf '%s' "$QUICKSTART_JSON" | jq -e '.mcp.mcp_url | contains("/mcp/local")' >/dev/null

echo "[5/7] Checking DreamFactory PostgreSQL API"
DF_ROWS="$(curl -fsS \
  "http://127.0.0.1:$DF_PORT/api/v2/demo_pgsql/_table/customers?limit=2" \
  -H "X-DreamFactory-Session-Token: $TOKEN")"
printf '%s' "$DF_ROWS" | jq -e '.resource | length == 2' >/dev/null
printf '%s' "$DF_ROWS" | jq -e '.resource[].name | select(. == "Acme Analytics")' >/dev/null

echo "[6/7] Initializing MCP and listing tools"
INIT_HEADERS="$TMP_DIR/init.headers"
curl -fsS -D "$INIT_HEADERS" -o /dev/null \
  -X POST "http://127.0.0.1:$MCP_PORT/mcp/local" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H "X-DreamFactory-Session-Token: $TOKEN" \
  -H "X-Mcp-Base-Url: http://127.0.0.1:$DF_PORT/api/v2" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"quickstart-smoke","version":"0.1"}}}'

SESSION_ID="$(awk 'BEGIN{IGNORECASE=1} /^mcp-session-id:/ {gsub("\r", "", $2); print $2}' "$INIT_HEADERS" | tail -1)"
if [ -z "$SESSION_ID" ]; then
  echo "MCP initialize did not return Mcp-Session-Id" >&2
  cat "$INIT_HEADERS" >&2
  exit 1
fi

curl -fsS -X POST "http://127.0.0.1:$MCP_PORT/mcp/local" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H "Mcp-Session-Id: $SESSION_ID" \
  -H "X-DreamFactory-Session-Token: $TOKEN" \
  -H "X-Mcp-Base-Url: http://127.0.0.1:$DF_PORT/api/v2" \
  -d '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}' >/dev/null

TOOLS_JSON="$(curl -fsS -X POST "http://127.0.0.1:$MCP_PORT/mcp/local" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H "Mcp-Session-Id: $SESSION_ID" \
  -H "X-DreamFactory-Session-Token: $TOKEN" \
  -H "X-Mcp-Base-Url: http://127.0.0.1:$DF_PORT/api/v2" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}')"
printf '%s' "$TOOLS_JSON" | jq -e '.result.tools[].name | select(. == "demo_pgsql_get_table_data")' >/dev/null

echo "[7/7] Calling MCP PostgreSQL data tool"
CALL_JSON="$(curl -fsS -X POST "http://127.0.0.1:$MCP_PORT/mcp/local" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H "Mcp-Session-Id: $SESSION_ID" \
  -H "X-DreamFactory-Session-Token: $TOKEN" \
  -H "X-Mcp-Base-Url: http://127.0.0.1:$DF_PORT/api/v2" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"demo_pgsql_get_table_data","arguments":{"tableName":"customers","limit":2}}}')"

MCP_TEXT="$(printf '%s' "$CALL_JSON" | jq -r '.result.content[0].text')"
printf '%s' "$MCP_TEXT" | jq -e '.resource | length == 2' >/dev/null
printf '%s' "$MCP_TEXT" | jq -e '.resource[].name | select(. == "Acme Analytics")' >/dev/null

echo "MCP PostgreSQL smoke test passed: MCP tool returned PostgreSQL rows through DreamFactory API"
