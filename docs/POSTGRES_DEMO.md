# PostgreSQL Demo

This flow connects DreamFactory to an existing PostgreSQL database and exposes
tables through the API.

## 1. Prepare PostgreSQL

Create a database and sample table with any PostgreSQL instance you control:

```sql
CREATE TABLE widgets (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  status TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO widgets (name, status, quantity) VALUES
  ('starter-kit', 'ready', 42),
  ('field-gateway', 'testing', 12),
  ('analytics-feed', 'ready', 7);
```

## 2. Generate A Service Payload

```bash
./dreamfactory service plan pgsql > pgsql-service.json
```

Edit `pgsql-service.json`:

```json
{
  "resource": [
    {
      "name": "demo_pgsql",
      "label": "Demo PostgreSQL",
      "type": "pgsql",
      "is_active": true,
      "config": {
        "host": "localhost",
        "port": 5432,
        "database": "app",
        "username": "app",
        "password": "change-me"
      }
    }
  ]
}
```

## 3. Apply The Service

```bash
./dreamfactory service apply \
  --file pgsql-service.json \
  --email you@company.example \
  --password YourPassword123456
```

## 4. Inspect And Query

```bash
./dreamfactory service inspect demo_pgsql \
  --email you@company.example \
  --password YourPassword123456
```

```bash
TOKEN="$(./dreamfactory login \
  --email you@company.example \
  --password YourPassword123456 \
  --token-only)"

curl -s http://localhost:8080/api/v2/demo_pgsql/_table/widgets \
  -H "X-DreamFactory-Session-Token: $TOKEN"
```

## LLM-Oriented Equivalent

```bash
./dreamfactory ai plan-service pgsql > pgsql-service.json
./dreamfactory ai apply-service --file pgsql-service.json \
  --email you@company.example \
  --password YourPassword123456
./dreamfactory ai inspect-service demo_pgsql \
  --email you@company.example \
  --password YourPassword123456
```
