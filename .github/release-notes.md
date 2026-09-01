DreamFactory Quickstart for DreamFactory 7.7.0.

A single self-contained Linux x86_64 archive: bundled DreamFactory 7.7.0
runtime (Laravel 13), Admin UI, database connectors (MySQL, PostgreSQL, SQL
Server, SQLite), CLI helpers, AI connection/chat service types, and the
built-in MCP server for governed LLM data access. No PHP, web server, or
database setup required.

Run it on Windows 11 via WSL2 (it is a native Linux binary).

One-line install:

```bash
curl -fsSL https://github.com/dreamfactorysoftware/dreamfactory-quickstart/releases/latest/download/install.sh | bash
```

Or run with npx (no install):

```bash
npx @dreamfactory/quickstart
```

Start DreamFactory:

```bash
dreamfactory serve
```

On first run, DreamFactory prompts for the admin email and password. For
non-interactive environments, pass `--admin-email` and `--admin-password`.

Manual download:

```bash
curl -LO https://github.com/dreamfactorysoftware/dreamfactory-quickstart/releases/latest/download/dreamfactory-quickstart-linux-x86_64.tar.gz
curl -LO https://github.com/dreamfactorysoftware/dreamfactory-quickstart/releases/latest/download/SHA256SUMS
sha256sum -c SHA256SUMS
tar xzf dreamfactory-quickstart-linux-x86_64.tar.gz
cd dreamfactory-quickstart
./dreamfactory serve --host 0.0.0.0 --port 8080 --admin-email you@company.example --admin-password YourPassword123456
```
