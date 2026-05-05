# PostgreSQL Demo

This is the primary product demo path. It connects DreamFactory to PostgreSQL,
seeds a real table, registers a service, and exposes the data through the API.

## 1. Prepare PostgreSQL

Create a database with any PostgreSQL instance you control. The quickstart CLI
can seed the sample table if the database already exists and credentials are
valid:

Optional local PostgreSQL container for demos:

```bash
docker run --rm --name dreamfactory-pg-demo \
  -e POSTGRES_DB=app \
  -e POSTGRES_USER=app \
  -e POSTGRES_PASSWORD=change-me \
  -p 15432:5432 \
  postgres:16-alpine
```

```bash
./dreamfactory demo pgsql \
  --db-host localhost \
  --db-port 15432 \
  --db-name app \
  --db-user app \
  --db-password change-me \
  --email you@company.example \
  --password YourPassword123456
```

The command creates the `widgets` table if needed, replaces the sample rows,
registers the `demo_pgsql` service, and prints API URLs.

Manual sample table SQL:

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

## 2. Manual Service Payload

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

## 3. Manual Apply

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
./dreamfactory ai demo-pgsql \
  --db-host localhost \
  --db-name app \
  --db-user app \
  --db-password change-me \
  --email you@company.example \
  --password YourPassword123456
./dreamfactory ai apply-service --file pgsql-service.json \
  --email you@company.example \
  --password YourPassword123456
./dreamfactory ai inspect-service demo_pgsql \
  --email you@company.example \
  --password YourPassword123456
```
