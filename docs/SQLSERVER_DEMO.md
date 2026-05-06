# SQL Server Demo

Use DreamFactory Quickstart when a generated app, AI coding assistant, or MCP
workflow needs governed access to SQL Server without embedding database
credentials in application code.

Start DreamFactory:

```bash
npx @dreamfactory/quickstart
```

Open `http://localhost:8080/`, create the admin user, then add a SQL Server
service in the Admin UI or with the CLI.

DreamFactory Quickstart includes the SQL Server connector and bundled Microsoft
ODBC Driver 18 runtime in the Linux x86_64 archive.

## Service Payload

Generate a starter payload:

```bash
npx @dreamfactory/quickstart service plan sqlsrv > sqlsrv-service.json
```

Example DreamFactory service creation payload:

```json
{
  "resource": [
    {
      "name": "mssql_test",
      "label": "SQL Server Test",
      "type": "sqlsrv",
      "is_active": true,
      "config": {
        "host": "host.docker.internal",
        "port": 11433,
        "database": "dfmini",
        "username": "sa",
        "password": "YourStrong!Passw0rd",
        "encrypt": false,
        "trust_server_certificate": true
      }
    }
  ]
}
```

Create the service:

```bash
curl -s -X POST "$BASE/system/service" \
  -H "Content-Type: application/json" \
  -H "X-DreamFactory-Session-Token: $TOKEN" \
  -d @examples/sqlsrv-service.json | jq .
```

List tables:

```bash
curl -s "$BASE/mssql_test/_table" \
  -H "X-DreamFactory-Session-Token: $TOKEN" | jq .
```

Query a table:

```bash
curl -s "$BASE/mssql_test/_table/widgets" \
  -H "X-DreamFactory-Session-Token: $TOKEN" | jq .
```

Generated apps should call DreamFactory REST APIs instead of connecting directly
to SQL Server. LLM clients should use DreamFactory MCP tools for schema
discovery and governed data access.
