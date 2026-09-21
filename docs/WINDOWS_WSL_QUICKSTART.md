# Running DreamFactory Quickstart on Windows (via WSL)

This guide gets DreamFactory running on a Windows 10/11 machine using WSL2, and
shows how to reach the Admin UI from your normal Windows browser.

The DreamFactory quickstart is a single self-contained Linux binary (it includes
its own PHP, web server, database, and MCP server). WSL2 runs real Linux, so the
binary runs natively. Nothing else needs to be installed inside WSL.

Note: this build is x86_64 only. It runs on standard Intel/AMD Windows machines.
Windows on ARM is not supported by this binary.

---

## Step 1: Install WSL2 (one time)

Open PowerShell or Windows Terminal as Administrator and run:

```powershell
wsl --install
```

This installs WSL2 and Ubuntu. Reboot when prompted. On first launch Ubuntu asks
you to create a Linux username and password (this is your WSL login, unrelated to
DreamFactory).

If WSL is already installed, make sure it is version 2:

```powershell
wsl --status
```

---

## Step 2: Install DreamFactory (inside Ubuntu/WSL)

Open the Ubuntu terminal (Start menu > Ubuntu) and run:

```bash
curl -fsSL https://github.com/dreamfactorysoftware/dreamfactory-quickstart/releases/latest/download/install.sh | bash
```

This downloads the latest release and installs the `dreamfactory` command to
`~/.local/bin`. No other dependencies are required.

If the terminal says `dreamfactory: command not found` afterward, reload your
shell once:

```bash
source ~/.bashrc
```

---

## Step 3: Start DreamFactory

```bash
SERVER_PORT=8088 dreamfactory serve --admin-email you@yourcompany.com --admin-password 'YourStrongPass1!'
```

Notes:
- Use the `SERVER_PORT=` form shown above. Do not use `--host 0.0.0.0`: that makes
  the server try to bind privileged port 80 and fails unless you run as root.
- Pick any free port (8088 is fine). If a port is busy, change the number.
- The admin password needs length plus complexity (uppercase, a number, and a
  symbol). A simple all-lowercase password will be rejected.
- First run takes a few seconds to initialize the database and create the admin.
  Leave this terminal open while you are using DreamFactory; it is the server.

When it is ready you will see:

```
  Admin UI: http://localhost:8088/
  Listen:   http://0.0.0.0:8088
```

---

## Step 4: Open the UI from Windows

WSL2 automatically forwards `localhost` between Windows and Linux, so you do not
need any networking setup. Just open your normal Windows browser (Edge, Chrome,
etc.) and go to:

```
http://localhost:8088/
```

Log in with the admin email and password you set in Step 3.

That is it. The UI, the REST API (`/api/v2`), and the API docs all work from the
Windows browser at that same address.

---

## Stopping and restarting

- To stop the server: go back to the Ubuntu terminal and press `Ctrl + C`.
- To start it again later: rerun the Step 3 command.
- Your data persists between restarts in `~/.dreamfactory` inside WSL.

---

## Connecting an AI / MCP client (optional)

DreamFactory ships an MCP server, so an AI client (Claude Desktop, Cursor, etc.)
can use your governed APIs as tools. Start the server with MCP enabled:

```bash
SERVER_PORT=8088 dreamfactory serve --with-mcp --admin-email you@yourcompany.com --admin-password 'YourStrongPass1!'
```

In the Admin UI, go to the AI section and follow "Configure MCP" to get the
connection details for your client.

---

## Troubleshooting

- "address already in use": another program (or a previous run) holds that port.
  Pick a different `SERVER_PORT`, for example `SERVER_PORT=8090`.
- "bind: permission denied" on port 80: you used `--host`. Use the `SERVER_PORT=`
  form from Step 3 instead.
- Errors on `/api/v2/system/environment` after upgrading from an older build:
  your `~/.dreamfactory` has data from a previous version. For a clean test,
  remove it and start fresh: `rm -rf ~/.dreamfactory` then rerun Step 3.
- Cannot reach `localhost:8088` from Windows: confirm the server terminal still
  shows it running, and that you are on WSL2 (`wsl --status` in PowerShell).
