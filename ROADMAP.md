# DreamFactory Quickstart Roadmap

The marketing promise is simple: try DreamFactory without a sales call,
multi-container setup, or connector scavenger hunt. Download one archive, run
one command, connect data, and show governed APIs quickly.

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

## Ship The First Internal Demo

- Keep release archive naming stable: `dreamfactory-quickstart-linux-x86_64.tar.gz`.
- Add a checksum file and version metadata.
- Add a demo SQL Server recipe with sample data and service creation commands.
- Add a clean Ubuntu install walkthrough.
- Confirm fresh host behavior with no system ODBC install.
- Record known limitations and support boundaries.

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
- Add one-page recipes for PostgreSQL, MySQL, SQL Server, SQLite, RWS, and SOAP.
- Add troubleshooting for ports, storage reset, admin reset, and SQL Server TLS.

## AI Configuration CLI

Short term:

- `ai apply-service --file service.json`
- `ai list-service-types`
- `ai inspect-service SERVICE`
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

