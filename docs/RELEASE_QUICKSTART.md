# 60-Second Release Quickstart

This is the release-archive path for evaluating DreamFactory. It assumes the
archive was already built and published for the user's platform.

## Linux x86_64

Download these files into the same directory:

- `dreamfactory-quickstart-linux-x86_64.tar.gz`
- `SHA256SUMS`

Verify the archive:

```bash
sha256sum -c SHA256SUMS
```

Unpack and start DreamFactory:

```bash
tar xzf dreamfactory-quickstart-linux-x86_64.tar.gz
cd dreamfactory-quickstart

./dreamfactory serve \
  --admin-email you@company.example \
  --admin-password YourPassword123456
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

## Configure Data From The CLI

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
