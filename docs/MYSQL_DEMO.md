# MySQL Demo

Use DreamFactory Quickstart when a generated app, AI coding assistant, or MCP
workflow needs governed access to MySQL or MariaDB without embedding database
credentials in application code.

Start DreamFactory:

```bash
npx @dreamfactory/quickstart
```

Open `http://localhost:8080/`, create the admin user, then add a MySQL service
in the Admin UI or with the CLI.

## Service Payload

```bash
npx @dreamfactory/quickstart service plan mysql > mysql-service.json
```

Edit `mysql-service.json`:

```json
{
  "resource": [
    {
      "name": "app_mysql",
      "label": "App MySQL",
      "type": "mysql",
      "is_active": true,
      "config": {
        "host": "localhost",
        "port": 3306,
        "database": "app",
        "username": "app",
        "password": "change-me"
      }
    }
  ]
}
```

Apply it:

```bash
npx @dreamfactory/quickstart service apply \
  --file mysql-service.json \
  --email you@company.example \
  --password YourPassword123456
```

## Query From An App

```bash
TOKEN="$(npx @dreamfactory/quickstart login \
  --email you@company.example \
  --password YourPassword123456 \
  --token-only)"

curl -s http://localhost:8080/api/v2/app_mysql/_table \
  -H "X-DreamFactory-Session-Token: $TOKEN"
```

Generated apps should call DreamFactory REST APIs instead of connecting directly
to MySQL. LLM clients should use DreamFactory MCP tools for schema discovery and
governed data access.
