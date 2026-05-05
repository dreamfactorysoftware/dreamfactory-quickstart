# SQL Server Demo

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

