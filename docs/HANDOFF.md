# Handoff Notes

Start here after opening a new Codex session:

```bash
cd /data/projects/dreamfactory/dreamfactory-quickstart
git status --short
rg "Mini|df-mini|dreamfactory-mini"
```

Then verify the skeleton:

```bash
bash -n build-binary.sh smoke-binary.sh bin/dreamfactory-ctl
git status --short
```

Build when ready:

```bash
GITHUB_TOKEN="$(gh auth token)" ./build-binary.sh
./smoke-binary.sh dist/dreamfactory-quickstart-linux-x86_64.tar.gz
```

Known inherited work from `df-mini`:

- SQL Server binary support was tested with bundled Microsoft ODBC Driver 18.
- SOAP was added and smoke-tested.
- Fresh Ubuntu container workflow was proven manually.
- Admin setup should use explicit emails for demos, commonly
  `admin@dreamfactory.com` for internal testing only.

Do not push without explicit instruction.

