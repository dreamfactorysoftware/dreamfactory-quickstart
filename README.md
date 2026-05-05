# DreamFactory Quickstart

Fast local DreamFactory adoption: unpack, run one command, connect data, and
expose governed APIs.

This repository is the packaging and release home for the DreamFactory
quickstart binary. It is not a reduced DreamFactory fork. The goal is a low
friction first experience for OSS users and AI data access governance
evaluations.

## Release Goal

The business goal is to make trying DreamFactory require as little commitment as
possible. A new user should be able to evaluate DreamFactory without a sales
call, multi-container setup, package scavenger hunt, or cloud account.

The first release artifact is a Linux x86_64 archive, but the packaging strategy
should remain platform agnostic:

- keep the runtime contract the same across platforms: `dreamfactory serve`
- avoid host-level package installation for the first-run path
- keep persistent state in a single user-controlled directory
- make archive contents self-contained wherever licensing allows
- keep OS-specific details inside build/release packaging, not user workflow

## Current Target

The first binary profile is Linux x86_64 and includes:

- DreamFactory API and Admin UI
- SQLite system database
- PostgreSQL connector
- MySQL / MariaDB connector
- SQL Server connector with bundled Microsoft ODBC Driver 18 runtime
- SQLite connector
- Remote Web Services connector
- SOAP connector
- Early CLI framework for AI-assisted API configuration
- Optional MCP-enabled artifact with bundled `df-mcp-server` daemon and Node
  runtime

## Quickstart From A Release Archive

The release path is designed for a new user who wants to evaluate DreamFactory
without building from source.

```bash
tar xzf dreamfactory-quickstart-linux-x86_64.tar.gz
cd dreamfactory-quickstart

./dreamfactory serve --host 0.0.0.0 --port 8080 \
  --admin-email you@company.example \
  --admin-password YourPassword123456
```

Open `http://localhost:8080/`. The root path redirects to the Admin UI.

Persistent data defaults to `~/.dreamfactory`. Override it with:

```bash
DREAMFACTORY_STORAGE=/opt/dreamfactory-data ./dreamfactory serve
```

See [docs/RELEASE_QUICKSTART.md](docs/RELEASE_QUICKSTART.md) for checksum
verification, health checks, admin reset, and release metadata.

## Build Locally

This build needs Docker. Private DreamFactory package access may require a
read-only GitHub token in `GITHUB_TOKEN`.

```bash
GITHUB_TOKEN="$(gh auth token)" ./build-binary.sh
./smoke-binary.sh dist/dreamfactory-quickstart-linux-x86_64.tar.gz
```

Build the MCP-enabled artifact used for agent/client evaluations:

```bash
INCLUDE_MCP=true GITHUB_TOKEN="$(gh auth token)" ./build-binary.sh
./smoke-binary.sh dist/dreamfactory-quickstart-linux-x86_64.tar.gz
```

Build outputs:

- `dist/dreamfactory-linux-x86_64`: raw embedded FrankenPHP binary
- `dist/dreamfactory-quickstart/`: runnable package directory
- `dist/dreamfactory-quickstart-linux-x86_64.tar.gz`: release archive
- `dist/SHA256SUMS`: checksums for release verification

The archive includes `VERSION` and `release.json` metadata.

## Runtime Commands

```bash
./dreamfactory help
./dreamfactory version
./dreamfactory doctor
./dreamfactory serve --with-mcp
./dreamfactory mcp doctor
./dreamfactory login --email you@company.example --password YourPassword123456
./dreamfactory demo pgsql \
  --db-host localhost \
  --db-name app \
  --db-user app \
  --db-password change-me \
  --email you@company.example \
  --password YourPassword123456
./dreamfactory service supported-types
./dreamfactory service list-types --email you@company.example --password YourPassword123456
./dreamfactory service plan pgsql > service.json
./dreamfactory service apply --file service.json --email you@company.example --password YourPassword123456
./dreamfactory reset-admin --email you@company.example --password NewPassword123456
./dreamfactory artisan route:list
```

See [docs/CLI.md](docs/CLI.md) for the human and LLM-oriented CLI surface.
See [docs/POSTGRES_DEMO.md](docs/POSTGRES_DEMO.md) for the primary product demo
path and [docs/SQLITE_DEMO.md](docs/SQLITE_DEMO.md) for an offline smoke-test
fallback.

## API Demo

```bash
BASE=http://127.0.0.1:8080/api/v2

TOKEN=$(curl -s -X POST "$BASE/system/admin/session" \
  --data-urlencode "email=you@company.example" \
  --data-urlencode "password=YourPassword123456" | jq -r .session_token)

curl -s "$BASE/system/service_type" \
  -H "X-DreamFactory-Session-Token: $TOKEN" | jq .
```

## AI Helper CLI

The binary includes an intentionally small CLI surface that agents can use
without scraping docs.

```bash
./dreamfactory ai spec
./dreamfactory ai plan-service pgsql
./dreamfactory ai demo-pgsql \
  --db-host localhost \
  --db-name app \
  --db-user app \
  --db-password change-me \
  --email you@company.example \
  --password YourPassword123456
./dreamfactory ai plan-service sqlsrv
./dreamfactory ai plan-service soap
./dreamfactory ai apply-service --file service.json --session-token "$TOKEN"
./dreamfactory ai supported-service-types
./dreamfactory ai list-service-types --session-token "$TOKEN"
./dreamfactory ai inspect-service mydb --session-token "$TOKEN"
./dreamfactory ai login \
  --url http://localhost:8080/api/v2 \
  --email you@company.example \
  --password YourPassword123456
```

Planned next steps:

- `ai grant-role` to generate least-privilege role access
- `ai create-app-key` to produce scoped API keys
- `ai inspect` to emit machine-readable service/table metadata

## Repository Role

Recommended repo split:

- `dreamfactory/dreamfactory`: core application source
- `dreamfactory/dreamfactory-quickstart`: binary packaging, releases, install
  workflow, smoke tests, and demo scripts
- `dreamfactory/df-mini`: historical mini Docker/container experiment

Before a public release, complete the license review for bundled Microsoft ODBC
runtime files and any DreamFactory package redistribution requirements.
