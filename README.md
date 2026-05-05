# DreamFactory Quickstart

Fast local DreamFactory adoption from one Linux archive: unpack, run one command,
connect data, and expose governed APIs.

This repository is the packaging and release home for the DreamFactory
quickstart binary. It is not a reduced DreamFactory fork. The goal is a low
friction first experience for OSS users and AI data access governance
evaluations.

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

## Quickstart From A Release Archive

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

## Build Locally

This build needs Docker. Private DreamFactory package access may require a
read-only GitHub token in `GITHUB_TOKEN`.

```bash
GITHUB_TOKEN="$(gh auth token)" ./build-binary.sh
./smoke-binary.sh dist/dreamfactory-quickstart-linux-x86_64.tar.gz
```

Build outputs:

- `dist/dreamfactory-linux-x86_64`: raw embedded FrankenPHP binary
- `dist/dreamfactory-quickstart/`: runnable package directory
- `dist/dreamfactory-quickstart-linux-x86_64.tar.gz`: release archive

## Runtime Commands

```bash
./dreamfactory help
./dreamfactory doctor
./dreamfactory reset-admin --email you@company.example --password NewPassword123456
./dreamfactory artisan route:list
```

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
./dreamfactory ai plan-service sqlsrv
./dreamfactory ai plan-service soap
./dreamfactory ai login \
  --url http://localhost:8080/api/v2 \
  --email you@company.example \
  --password YourPassword123456
```

Planned next steps:

- `ai apply-service` to create a service from JSON
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

