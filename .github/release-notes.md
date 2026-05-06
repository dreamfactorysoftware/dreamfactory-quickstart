Initial DreamFactory Quickstart release.

Includes the Linux x86_64 self-contained archive, bundled DreamFactory runtime,
Admin UI, database connectors, CLI helpers, and MCP-enabled tooling for governed
LLM data access.

One-line install:

```bash
curl -fsSL https://github.com/dreamfactorysoftware/dreamfactory-quickstart/releases/latest/download/install.sh | bash
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
