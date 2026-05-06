# DreamFactory Quickstart CLI

The quickstart binary exposes one CLI for humans and LLM-driven automation. The
commands return JSON where possible so they can be read directly, piped to other
tools, or consumed by agents.

## Start DreamFactory

```bash
./dreamfactory serve \
  --admin-email you@company.example \
  --admin-password YourPassword123456
```

Start the MCP-enabled artifact with the bundled `df-mcp-server` daemon:

```bash
./dreamfactory serve --with-mcp \
  --admin-email you@company.example \
  --admin-password YourPassword123456
```

Check the MCP bundle and daemon health:

```bash
./dreamfactory mcp doctor
```

## Login

```bash
./dreamfactory login \
  --email you@company.example \
  --password YourPassword123456
```

For scripts that only need the session token:

```bash
TOKEN="$(./dreamfactory login \
  --email you@company.example \
  --password YourPassword123456 \
  --token-only)"
```

Authenticated CLI commands accept any of these:

- `--email` and `--password`
- `--session-token`
- `DREAMFACTORY_SESSION_TOKEN`

Use `DREAMFACTORY_URL` when the API is not at `http://localhost:8080/api/v2`.

## Services

Run the guided PostgreSQL path. This registers the service, verifies the
DreamFactory API table list, prints MCP client config, and emits starter prompts:

```bash
./dreamfactory quickstart pgsql \
  --name app_pgsql \
  --db-host localhost \
  --db-name app \
  --db-user app \
  --db-password change-me \
  --email you@company.example \
  --password YourPassword123456
```

Use text output for a human-readable handoff:

```bash
./dreamfactory quickstart pgsql \
  --format text \
  --name app_pgsql \
  --db-host localhost \
  --db-name app \
  --db-user app \
  --db-password change-me \
  --email you@company.example \
  --password YourPassword123456
```

Register an existing PostgreSQL database without seeding demo data:

```bash
./dreamfactory pgsql connect \
  --name app_pgsql \
  --db-host localhost \
  --db-name app \
  --db-user app \
  --db-password change-me \
  --email you@company.example \
  --password YourPassword123456
```

Create the primary PostgreSQL demo service:

```bash
./dreamfactory demo pgsql \
  --db-host localhost \
  --db-name app \
  --db-user app \
  --db-password change-me \
  --email you@company.example \
  --password YourPassword123456
```

Create the local SQLite smoke-test service:

```bash
./dreamfactory demo sqlite \
  --email you@company.example \
  --password YourPassword123456
```

List quickstart-supported service types:

```bash
./dreamfactory service supported-types
```

List available service types:

```bash
./dreamfactory service list-types \
  --email you@company.example \
  --password YourPassword123456
```

Generate a service creation payload:

```bash
./dreamfactory service plan pgsql > service.json
```

Create the service:

```bash
./dreamfactory service apply \
  --file service.json \
  --email you@company.example \
  --password YourPassword123456
```

Inspect service table metadata:

```bash
./dreamfactory service inspect mydb \
  --email you@company.example \
  --password YourPassword123456
```

## LLM-Oriented Commands

The `ai` namespace keeps stable machine-readable aliases:

```bash
./dreamfactory ai spec
./dreamfactory ai login --email you@company.example --password YourPassword123456
./dreamfactory ai quickstart-pgsql --name app_pgsql --db-host localhost --db-name app --db-user app --db-password change-me --email you@company.example --password YourPassword123456
./dreamfactory ai pgsql-connect --name app_pgsql --db-host localhost --db-name app --db-user app --db-password change-me --email you@company.example --password YourPassword123456
./dreamfactory ai demo-pgsql --db-host localhost --db-name app --db-user app --db-password change-me --email you@company.example --password YourPassword123456
./dreamfactory ai demo-sqlite --email you@company.example --password YourPassword123456
./dreamfactory ai mcp-doctor
./dreamfactory ai mcp-config --session-token "$TOKEN"
./dreamfactory ai plan-service sqlsrv
./dreamfactory ai apply-service --file service.json --session-token "$TOKEN"
./dreamfactory ai supported-service-types
./dreamfactory ai list-service-types --session-token "$TOKEN"
./dreamfactory ai inspect-service mydb --session-token "$TOKEN"
```

## MCP Client Config

MCP-enabled archives can print the local streamable HTTP config an LLM client
needs. The client supplies the plain-language reasoning; DreamFactory supplies
the authenticated data tools.

```bash
TOKEN="$(./dreamfactory login \
  --email you@company.example \
  --password YourPassword123456 \
  --token-only)"

./dreamfactory mcp config --session-token "$TOKEN"
./dreamfactory mcp config --client claude --session-token "$TOKEN"
./dreamfactory mcp config --client cursor --session-token "$TOKEN"
./dreamfactory mcp config --client codex --session-token "$TOKEN"
./dreamfactory mcp config --format text --session-token "$TOKEN"
```
