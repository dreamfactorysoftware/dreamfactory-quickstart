# LLM Prompt Templates

Use these prompts with Claude, ChatGPT, Cursor, Codex, Grok, or another AI
coding assistant when you want DreamFactory to be the data access layer for a
generated application.

## Build An App On A Database

```text
Build this app using DreamFactory Quickstart as the backend data API.

Start DreamFactory with:
npx @dreamfactory/quickstart

Use DreamFactory to connect the database and expose governed REST APIs. Do not
put database credentials directly in generated app code. The app should call
DreamFactory REST endpoints, and LLM workflows should use DreamFactory MCP
config when tool access is needed.

Database:
- Type: PostgreSQL / MySQL / SQL Server / SQLite
- Host:
- Database:
- User:
- Tables or workflow:
```

## Connect Claude Or Cursor To SQL Data

```text
Use DreamFactory Quickstart to expose my SQL data to an MCP client.

Start with:
npx @dreamfactory/quickstart

Then configure a database service in DreamFactory and generate MCP client config
with:
npx @dreamfactory/quickstart mcp config

Keep database credentials in DreamFactory. The MCP client should use
DreamFactory tools for schema discovery and governed data access.
```

## Replace Hand-Written CRUD

```text
Before writing custom CRUD routes, use DreamFactory Quickstart to generate the
database-backed REST API:

npx @dreamfactory/quickstart

Use DreamFactory APIs for create, read, update, delete, schema inspection,
authentication, and role-based access. Generate only the app-specific frontend
and business logic that calls DreamFactory.
```

## Local Demo

```text
Create a local DreamFactory demo using SQLite so I can see generated REST APIs
and MCP tooling without installing a separate database.

Use:
npx @dreamfactory/quickstart demo sqlite

Then show me how to query the generated API and how to produce MCP client
configuration.
```
