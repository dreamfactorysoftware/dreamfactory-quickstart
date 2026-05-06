# DreamFactory Quickstart

Run DreamFactory locally in minutes, connect real data, and expose governed APIs
that humans, applications, and LLM tools can use safely.

DreamFactory Quickstart packages the DreamFactory API platform into a
self-contained Linux x86_64 archive. Download it, start one process, create an
admin user, and begin turning databases and services into secure REST APIs.

## Why Use It

- Evaluate DreamFactory without a cloud account, sales call, or multi-container
  setup.
- Turn PostgreSQL, MySQL, SQL Server, SQLite, REST, and SOAP services into
  governed APIs.
- Give LLM clients controlled access to enterprise data through DreamFactory's
  API and MCP tooling.
- Keep data local by default, with persistent state in `~/.dreamfactory`.
- Move from first run to API calls, MCP config, and data demos from one CLI.

## What's Included

- DreamFactory API platform and Admin UI
- SQLite system database
- PostgreSQL connector
- MySQL / MariaDB connector
- SQL Server connector with bundled Microsoft ODBC Driver 18 runtime
- SQLite connector
- Remote Web Services connector
- SOAP connector
- CLI helpers for setup, login, service creation, API inspection, and demos
- MCP-enabled package with bundled `df-mcp-server` daemon and Node runtime

## Download And Run

Install the latest Linux x86_64 release:

```bash
curl -fsSL https://raw.githubusercontent.com/dreamfactorysoftware/dreamfactory-quickstart/master/install.sh | bash
```

Start DreamFactory:

```bash
dreamfactory serve --host 0.0.0.0 --port 8080 \
  --admin-email you@company.example \
  --admin-password YourPassword123456
```

Open `http://localhost:8080/`. The root path redirects to the Admin UI.

The installer downloads the release archive, verifies `SHA256SUMS`, extracts to
`~/.local/share/dreamfactory-quickstart`, and links `dreamfactory` into
`~/.local/bin`.

Manual download is also available:

```bash
curl -LO https://github.com/dreamfactorysoftware/dreamfactory-quickstart/releases/download/v0.1.0-mcp/dreamfactory-quickstart-linux-x86_64.tar.gz
curl -LO https://github.com/dreamfactorysoftware/dreamfactory-quickstart/releases/download/v0.1.0-mcp/SHA256SUMS
sha256sum -c SHA256SUMS
tar xzf dreamfactory-quickstart-linux-x86_64.tar.gz
cd dreamfactory-quickstart

./dreamfactory serve --host 0.0.0.0 --port 8080 \
  --admin-email you@company.example \
  --admin-password YourPassword123456
```

The first run initializes local storage, runs migrations, creates the admin
user, and starts the API and Admin UI.

Persistent data defaults to `~/.dreamfactory`. Override it with:

```bash
DREAMFACTORY_STORAGE=/opt/dreamfactory-data ./dreamfactory serve
```

See [docs/RELEASE_QUICKSTART.md](docs/RELEASE_QUICKSTART.md) for checksum
verification, health checks, admin reset, and release metadata.

## Connect A Database

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

This registers the PostgreSQL service, verifies the DreamFactory table-list API,
prints MCP client config, and returns starter prompts for LLM workflows.

For an offline local demo:

```bash
./dreamfactory demo sqlite \
  --email you@company.example \
  --password YourPassword123456
```

See [docs/POSTGRES_DEMO.md](docs/POSTGRES_DEMO.md) for the full PostgreSQL
demo and [docs/SQLITE_DEMO.md](docs/SQLITE_DEMO.md) for the offline path.

## LLM And MCP Workflows

DreamFactory gives LLM clients a governed tool layer instead of direct database
credentials. The client handles language reasoning; DreamFactory handles
authentication, service access, API enforcement, and data source connectivity.

```bash
./dreamfactory serve --with-mcp

TOKEN="$(./dreamfactory login \
  --email you@company.example \
  --password YourPassword123456 \
  --token-only)"

./dreamfactory mcp config --session-token "$TOKEN"
./dreamfactory mcp config --client cursor --session-token "$TOKEN"
```

After a service such as `app_pgsql` is registered, MCP clients can discover
tools for table listing, schema inspection, and governed data access.

## Useful Commands

```bash
./dreamfactory help
./dreamfactory version
./dreamfactory doctor
./dreamfactory mcp doctor
./dreamfactory service supported-types
./dreamfactory service plan pgsql > service.json
./dreamfactory service apply --file service.json --email you@company.example --password YourPassword123456
./dreamfactory service inspect app_pgsql --email you@company.example --password YourPassword123456
./dreamfactory reset-admin --email you@company.example --password NewPassword123456
```

See [docs/CLI.md](docs/CLI.md) for the full CLI surface.

## API Example

```bash
BASE=http://127.0.0.1:8080/api/v2

TOKEN="$(curl -s -X POST "$BASE/system/admin/session" \
  --data-urlencode "email=you@company.example" \
  --data-urlencode "password=YourPassword123456" | jq -r .session_token)"

curl -s "$BASE/system/service_type" \
  -H "X-DreamFactory-Session-Token: $TOKEN" | jq .
```

## Build From Source

This build needs Docker. Private DreamFactory package access may require a
read-only GitHub token in `GITHUB_TOKEN`.

```bash
GITHUB_TOKEN="$(gh auth token)" ./build-binary.sh
./smoke-binary.sh dist/dreamfactory-quickstart-linux-x86_64.tar.gz
```

Build the MCP-enabled archive with the bundled `df-mcp-server` daemon:

```bash
INCLUDE_MCP=true GITHUB_TOKEN="$(gh auth token)" ./build-binary.sh
./smoke-binary.sh dist/dreamfactory-quickstart-linux-x86_64.tar.gz
./smoke-mcp-pgsql.sh dist/dreamfactory-quickstart-linux-x86_64.tar.gz
```
