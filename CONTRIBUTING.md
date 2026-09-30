# Contributing

## Local setup

Create a virtual environment and install the project dependencies:

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

Run the API with:

```bash
uvicorn app.main:app --reload
```

Run the test suite with:

```bash
pytest
```

## Commit attribution

Before committing, configure Git with an email address associated with your
GitHub account so commits can appear in your contribution activity:

```bash
git config user.email "your-github-associated-email@example.com"
```
