# 60-Second Release Quickstart

This is the release-archive path for evaluating DreamFactory. It assumes the
archive was already built and published for the user's platform.

## Linux x86_64

Run with npm:

```bash
npx @dreamfactory/quickstart serve
```

The npm launcher downloads the matching GitHub release on first use and caches
it under `~/.cache/dreamfactory-quickstart`.

```bash
npx @dreamfactory/quickstart cache info
npx @dreamfactory/quickstart cache clean
```

Or install the latest release:

```bash
curl -fsSL https://raw.githubusercontent.com/dreamfactorysoftware/dreamfactory-quickstart/master/install.sh | bash
```

Start DreamFactory:

```bash
dreamfactory serve
```

On first run, DreamFactory prompts for the admin email and password. For
non-interactive environments, pass `--admin-email` and `--admin-password`.

Manual download is also available. Download these files into the same
directory:

```bash
curl -LO https://github.com/dreamfactorysoftware/dreamfactory-quickstart/releases/download/v0.1.0-mcp/dreamfactory-quickstart-linux-x86_64.tar.gz
curl -LO https://github.com/dreamfactorysoftware/dreamfactory-quickstart/releases/download/v0.1.0-mcp/SHA256SUMS
```

Verify the archive:

```bash
sha256sum -c SHA256SUMS
```

Unpack and start DreamFactory:

```bash
tar xzf dreamfactory-quickstart-linux-x86_64.tar.gz
cd dreamfactory-quickstart
```

Open:

```text
http://localhost:8080/
```

The first run initializes `~/.dreamfactory`, runs migrations, creates the admin
user, and starts the API and Admin UI.

For MCP-enabled archives, start the API and bundled MCP daemon together:

```bash
./dreamfactory serve --with-mcp \
  --admin-email you@company.example \
  --admin-password YourPassword123456
```

The daemon defaults to `http://127.0.0.1:8006`. Check it from the unpacked
directory:

```bash
./dreamfactory mcp doctor
```

## Persistent Data

Default storage:

```text
~/.dreamfactory
```

Custom storage:

```bash
DREAMFACTORY_STORAGE=/opt/dreamfactory-data ./dreamfactory serve \
  --admin-email you@company.example \
  --admin-password YourPassword123456
```

## Health Check

From the unpacked directory:

```bash
./dreamfactory version
./dreamfactory doctor
```

Release maintainers can run the PostgreSQL/MCP gate against an MCP-enabled
archive:

```bash
./smoke-mcp-pgsql.sh dist/dreamfactory-quickstart-linux-x86_64.tar.gz
```

## Configure Data From The CLI

Use the guided PostgreSQL path for the lowest-friction first run:

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

The command registers the service, verifies the DreamFactory table-list API,
prints MCP client config, and emits starter prompts for the LLM client.

For human-readable output:

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

Connect an existing PostgreSQL database without the extra quickstart output:

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

Primary PostgreSQL demo:

```bash
./dreamfactory demo pgsql \
  --db-host localhost \
  --db-name app \
  --db-user app \
  --db-password change-me \
  --email you@company.example \
  --password YourPassword123456
```

Offline smoke-test fallback:

```bash
./dreamfactory demo sqlite \
  --email you@company.example \
  --password YourPassword123456
```

## MCP For Plain-Language Clients

MCP-enabled archives expose DreamFactory APIs as MCP tools. The LLM client does
the plain-language interpretation, then calls those tools.

```bash
TOKEN="$(./dreamfactory login \
  --email you@company.example \
  --password YourPassword123456 \
  --token-only)"

./dreamfactory mcp config --session-token "$TOKEN"
./dreamfactory mcp config --client cursor --session-token "$TOKEN"
```

After a PostgreSQL service named `app_pgsql` is registered, clients should see
tools such as `app_pgsql_get_tables`, `app_pgsql_get_table_schema`, and
`app_pgsql_get_table_data`.

Generate a service payload:

```bash
./dreamfactory service plan pgsql > service.json
```

Edit `service.json` with your connection details, then apply it:

```bash
./dreamfactory service apply \
  --file service.json \
  --email you@company.example \
  --password YourPassword123456
```

## Reset The Admin User

```bash
./dreamfactory reset-admin \
  --email you@company.example \
  --password NewPassword123456
```

## Release Metadata

Each archive includes:

- `VERSION`: package version
- `release.json`: platform, build date, DreamFactory branch, and quickstart
  commit
- `mcp_enabled` in `release.json`: whether the archive includes the MCP daemon
  and bundled Node runtime

The user-facing command stays the same as more platforms are added:

```bash
./dreamfactory serve --admin-email you@company.example --admin-password YourPassword123456
```
