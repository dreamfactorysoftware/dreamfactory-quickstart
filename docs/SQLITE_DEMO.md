# SQLite Smoke Test

This is an offline smoke-test path for validating the quickstart without Docker
or an external database. The primary product demo is PostgreSQL.

Start DreamFactory:

```bash
./dreamfactory serve \
  --admin-email you@company.example \
  --admin-password YourPassword123456
```

In another terminal, create and register the demo service:

```bash
./dreamfactory demo sqlite \
  --email you@company.example \
  --password YourPassword123456
```

The command creates:

- `~/.dreamfactory/databases/demo.sqlite`
- service name `demo_sqlite`
- tables `widgets` and `sites`

Inspect the service:

```bash
./dreamfactory service inspect demo_sqlite \
  --email you@company.example \
  --password YourPassword123456
```

Query the API:

```bash
TOKEN="$(./dreamfactory login \
  --email you@company.example \
  --password YourPassword123456 \
  --token-only)"

curl -s http://localhost:8080/api/v2/demo_sqlite/_table/widgets \
  -H "X-DreamFactory-Session-Token: $TOKEN"
```

Reset the demo data:

```bash
./dreamfactory demo sqlite \
  --email you@company.example \
  --password YourPassword123456 \
  --force
```

LLM-oriented equivalent:

```bash
./dreamfactory ai demo-sqlite \
  --email you@company.example \
  --password YourPassword123456
```
