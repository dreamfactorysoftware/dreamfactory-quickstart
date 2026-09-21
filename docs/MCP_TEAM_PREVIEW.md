# DreamFactory + MCP on your laptop (team preview)

One binary. No server, no Docker, no Composer. Linux x86_64, or Windows 11 via WSL2.

## 1. Install

Windows: install WSL2 first (`wsl --install` in an admin PowerShell, reboot, open Ubuntu).
Full walkthrough: `WINDOWS_WSL_QUICKSTART.md`.

Inside Linux / Ubuntu-on-WSL:

```bash
curl -fsSL https://github.com/dreamfactorysoftware/dreamfactory-quickstart/releases/download/v0.1.7-preview/install.sh \
  | DREAMFACTORY_QUICKSTART_VERSION=v0.1.7-preview bash
```

## 2. Run

```bash
dreamfactory serve --with-mcp
```

First run asks for an admin email and password. Then:

- Admin UI: http://localhost:8080/
- REST API: http://localhost:8080/api/v2
- MCP endpoint per MCP service: http://localhost:8080/mcp/<service-name>

Data lives in `~/.dreamfactory`. Stop with Ctrl+C, run the same command to resume.

## 3. Connect SQL Server

Admin UI > API Generation & Connections > Create > SQL Server. Host, port, database,
user, password. For a server with a self-signed certificate set
"Trust server certificate" on and "Encrypt" to `no`.

Test it: http://localhost:8080/api/v2/<service>/_table (log in first, or use an API key).

## 4. Expose it over MCP

Admin UI > AI > MCP > Create. Pick the SQL Server service in the Exposure grid,
turn on the verbs you want (read, spec, procedures, write). The page shows how many
tools the server advertises and roughly what they cost per turn.

Access: the Access tab needs a role that can reach both the MCP service and the
database service. "Require role access" is on by default for new servers.

## 5. Point an agent at it

Connect tab shows ready-made config for Claude Desktop, Claude Code, Cursor and a
generic client. OAuth login is the default; turn on "Allow API key auth" on the MCP
service to use an app API key instead (header `X-DreamFactory-API-Key`).

Quick check from a shell:

```bash
curl -s -X POST http://localhost:8080/mcp/<service> \
  -H 'X-DreamFactory-API-Key: <app key>' -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

## Also in the box

- `system_mcp` service type: an MCP server over the DreamFactory admin API itself
  (bundled daemon on port 3700). Admin-level; needs a session or OAuth login.
- API Builder and Agents service types.
- `dreamfactory mcp doctor` checks both daemons. `dreamfactory --help` lists the rest.

## Known limits of this preview

- Linux x86_64 only. macOS builds are not published yet.
- Built from development branches (MCP exposure work under review). Expect changes.
- Each install is its own instance with its own SQLite config; nothing is shared.
