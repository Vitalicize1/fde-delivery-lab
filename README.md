# Customer Operations API

Week 4 starter project: a small FastAPI service for managing customer support tickets.
It uses typed Pydantic models and an in-memory Python dictionary, so it is easy to read
and run without setting up a database. Data is cleared whenever the server restarts.

## Setup

Python 3.10 or newer is recommended.

```bash
python -m venv .venv
source .venv/bin/activate       # Windows: .venv\Scripts\activate
python -m pip install -r requirements.txt
```

## Run the API

From the project directory:

```bash
uvicorn app.main:app --reload
```

The API runs at <http://127.0.0.1:8000>. The `--reload` option restarts the server
when you edit Python files; it is useful during learning and development.

## Automatic API documentation

FastAPI reads the type hints and Pydantic models in `app/main.py` to generate an
OpenAPI schema automatically. While the server is running, open:

- Swagger UI: <http://127.0.0.1:8000/docs> — interactively try each endpoint.
- ReDoc: <http://127.0.0.1:8000/redoc> — browse a readable reference view.
- Raw OpenAPI JSON: <http://127.0.0.1:8000/openapi.json> — the machine-readable schema.

The `response_model=Ticket` settings document and validate response shapes, while
the Pydantic request models document required fields and validate incoming JSON.

## Endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/` | Health message and docs link |
| `POST` | `/tickets` | Create a ticket |
| `GET` | `/tickets` | List all tickets |
| `GET` | `/tickets/{ticket_id}` | Get one ticket |
| `PATCH` | `/tickets/{ticket_id}` | Update supplied fields |
| `DELETE` | `/tickets/{ticket_id}` | Delete a ticket |

Example request:

```bash
curl -X POST http://127.0.0.1:8000/tickets \
  -H 'Content-Type: application/json' \
  -d '{
    "customer_name": "Ada Lovelace",
    "subject": "Cannot sign in",
    "description": "The password reset email never arrives.",
    "priority": "high"
  }'
```

Tickets default to `priority: normal` and `status: open`. You can also set the
initial status while opening a ticket, then change it with `PATCH`:

```bash
curl -X POST http://127.0.0.1:8000/tickets \
  -H 'Content-Type: application/json' \
  -d '{
    "customer_name": "Ada Lovelace",
    "subject": "Cannot sign in",
    "description": "The password reset email never arrives.",
    "priority": "high",
    "status": "pending"
  }'

curl -X PATCH http://127.0.0.1:8000/tickets/1 \
  -H 'Content-Type: application/json' \
  -d '{"status": "closed", "priority": "normal", "owner": "Grace Hopper"}'
```

Supported priorities are `low`, `normal`, and `high`. Supported statuses are
`open`, `pending`, and `closed`; invalid values are rejected with a validation error.
The optional `owner` field identifies the assigned support owner and can be set when
creating a ticket or changed later with `PATCH`.

## Run tests

```bash
pytest
```

The tests use FastAPI's `TestClient` and cover creation, listing, retrieval,
partial updates, deletion, missing tickets, and invalid request validation.

## Important files

- `app/main.py` — FastAPI app, Pydantic models, temporary storage, and CRUD routes.
- `tests/test_main.py` — endpoint tests; each test starts with an empty in-memory store.
- `requirements.txt` — runtime, server, and test dependencies.
- `.gitignore` — ignores virtual environments and generated Python/test files.

## Next learning steps

Once the route and model basics feel comfortable, replace the `tickets` dictionary
with a database, add authentication, and constrain `priority` and `status` with
Pydantic `Literal` or enum types.
