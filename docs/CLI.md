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

Create the local SQLite demo service:

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
./dreamfactory ai demo-sqlite --email you@company.example --password YourPassword123456
./dreamfactory ai plan-service sqlsrv
./dreamfactory ai apply-service --file service.json --session-token "$TOKEN"
./dreamfactory ai supported-service-types
./dreamfactory ai list-service-types --session-token "$TOKEN"
./dreamfactory ai inspect-service mydb --session-token "$TOKEN"
```
