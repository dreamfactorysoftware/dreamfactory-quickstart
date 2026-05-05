# DreamFactory Quickstart Roadmap

The marketing promise is simple: try DreamFactory without a sales call,
multi-container setup, cloud account, or connector scavenger hunt. Download one
archive, run one command, connect data, and show governed APIs quickly.

## Product Principle

Reduce evaluation friction first. Every release decision should protect the
shortest path from curiosity to a running DreamFactory instance:

- no required sales touch
- no required Docker or Kubernetes for the release archive path
- no required host package installation for the first-run path
- one obvious command to start DreamFactory
- one obvious place for persistent data
- connectors available without add-on discovery for common evaluation targets

The initial Linux x86_64 package is the first proof point, not the long-term
platform boundary. Keep the user-facing workflow platform neutral so future
Linux ARM64, macOS, Windows, VM, or container artifacts can expose the same
shape:

```bash
./dreamfactory serve --admin-email you@company.example --admin-password YourPassword123456
```

## Current State

- Static Linux x86_64 package builds through FrankenPHP static builder.
- Admin UI is embedded and root redirects to `/dreamfactory/dist/index.html`.
- First run initializes SQLite storage, runs migrations, and creates an admin.
- Binary connector target is present: PostgreSQL, MySQL / MariaDB, SQL Server,
  SQLite, Remote Web Services, and SOAP.
- SQL Server works with bundled Microsoft ODBC Driver 18 runtime files.
- Internal smoke test covers server boot, root redirect, Admin UI, API response,
  admin login, `doctor`, and `ai login`.
- Early AI helper commands exist: `ai spec`, `ai login`, and
  `ai plan-service`.
- First human/LLM CLI service commands exist locally: login, list service
  types, plan service payloads, apply services, and inspect service metadata.
- PostgreSQL is the primary product demo path. SQLite remains available as a
  no-external-dependency smoke-test fallback.

## Ship The First Internal Demo

- Keep release archive naming stable: `dreamfactory-quickstart-linux-x86_64.tar.gz`.
- Add a checksum file and version metadata. (Done locally; validate on next
  full build.)
- Add a demo SQL Server recipe with sample data and service creation commands.
- Add a clean Ubuntu install walkthrough. (Started with release quickstart.)
- Confirm fresh host behavior with no system ODBC install.
- Record known limitations and support boundaries.

## Platform-Agnostic Release Strategy

- Treat `dreamfactory serve` as the stable product interface.
- Keep platform differences in artifact names, checksums, and build scripts.
- Prefer self-contained archives over installers until the archive experience is
  proven.
- Add installer scripts only as thin convenience wrappers around signed,
  checksum-verified archives.
- Keep storage override behavior consistent through `DREAMFACTORY_STORAGE`.
- Validate each platform artifact with the same smoke-test expectations: server
  boot, Admin UI load, API response, admin login, `doctor`, and AI helper login.

Candidate artifact ladder:

- Linux x86_64 archive
- Linux ARM64 archive
- macOS Apple Silicon archive
- macOS Intel archive, if demand justifies it
- Windows archive or installer, after runtime and extension constraints are
  understood
- container image, as an alternate path for teams that already standardize on
  containers

## Public Release Checklist

- Resolve static-builder sanity-check failure instead of tolerating it after
  binary creation.
- Review Microsoft ODBC Driver redistribution terms.
- Review redistribution terms for all bundled DreamFactory packages.
- Decide release cadence and whether artifacts are published from this repo or
  from the main DreamFactory CI.
- Add CI that builds, extracts, and smoke-tests the archive.
- Add signed checksums or provenance metadata.
- Add main `dreamfactory` repo docs linking to this quickstart.

## Adoption Workflow

- Make `serve --admin-email --admin-password` the canonical non-interactive path.
- Keep interactive setup for humans who run without flags.
- Add `install.sh` only after release artifacts and checksums are stable.
- Add the PostgreSQL recipe first, with SQLite retained for offline smoke tests.
- Add troubleshooting for ports, storage reset, admin reset, and SQL Server TLS.

## AI Configuration CLI

Short term:

- `ai list-service-types`
- `ai create-app-key --role ROLE --name NAME`

Medium term:

- Generate least-privilege roles from table/action intent.
- Emit API docs and examples scoped to an app/API key.
- Support dry-run plans before applying changes.
- Return machine-readable errors and remediation hints.

## Package Candidates

Default binary profile:

- `df-core`, `df-system`, `df-user`, `df-cache`, `df-apidoc`, `df-file`
- `df-sqldb`, `df-mysqldb`, `df-sqlsrv`, `df-rws`, `df-soap`
- `df-admin-interface`

Strong next candidates:

- `df-endpoint-builder`: useful for governed API recipes and AI-created
  endpoints.
- `df-mcp-server`: strategically relevant, but needs runtime/process packaging
  review.

Defer from default binary until there is a specific adoption story:

- Heavy native database drivers such as Oracle, DB2, HANA, Snowflake, Trino,
  Databricks, Cassandra, Hadoop, and MongoDB.
- Enterprise auth/messaging packages such as SAML, LDAP, AMQP, MQTT, Pub/Sub.
- Scheduler, scripting, AI chat, guardian, and other features that broaden the
  first-run surface area.
