"""Endpoint tests for the customer operations API."""

import pytest
from fastapi.testclient import TestClient

from app.main import app, tickets


@pytest.fixture(autouse=True)
def clear_in_memory_storage() -> None:
    """Keep tests independent by clearing the temporary store before each test."""

    tickets.clear()


client = TestClient(app)


def ticket_payload() -> dict[str, str]:
    return {
        "customer_name": "Ada Lovelace",
        "subject": "Cannot sign in",
        "description": "The password reset email never arrives.",
        "priority": "high",
    }


def test_create_ticket_returns_created_ticket() -> None:
    response = client.post("/tickets", json=ticket_payload())

    assert response.status_code == 201
    assert response.json() == {
        **ticket_payload(),
        "id": 1,
        "status": "open",
        "owner": None,
    }


def test_create_ticket_can_start_with_selected_status() -> None:
    response = client.post("/tickets", json={**ticket_payload(), "status": "pending"})

    assert response.status_code == 201
    assert response.json()["status"] == "pending"


def test_list_and_get_tickets() -> None:
    create_response = client.post("/tickets", json=ticket_payload())
    ticket_id = create_response.json()["id"]

    list_response = client.get("/tickets")
    get_response = client.get(f"/tickets/{ticket_id}")

    assert list_response.status_code == 200
    assert len(list_response.json()) == 1
    assert get_response.status_code == 200
    assert get_response.json()["subject"] == "Cannot sign in"


def test_update_ticket() -> None:
    create_response = client.post("/tickets", json=ticket_payload())
    ticket_id = create_response.json()["id"]

    response = client.patch(
        f"/tickets/{ticket_id}",
        json={"status": "closed", "priority": "normal", "owner": "Grace Hopper"},
    )

    assert response.status_code == 200
    assert response.json()["status"] == "closed"
    assert response.json()["priority"] == "normal"
    assert response.json()["owner"] == "Grace Hopper"


def test_create_ticket_can_have_an_owner() -> None:
    response = client.post("/tickets", json={**ticket_payload(), "owner": "Grace Hopper"})

    assert response.status_code == 201
    assert response.json()["owner"] == "Grace Hopper"


def test_delete_ticket() -> None:
    create_response = client.post("/tickets", json=ticket_payload())
    ticket_id = create_response.json()["id"]

    delete_response = client.delete(f"/tickets/{ticket_id}")
    get_response = client.get(f"/tickets/{ticket_id}")

    assert delete_response.status_code == 204
    assert get_response.status_code == 404


@pytest.mark.parametrize("method, path", [("get", "/tickets/999"), ("delete", "/tickets/999")])
def test_missing_ticket_returns_not_found(method: str, path: str) -> None:
    response = getattr(client, method)(path)

    assert response.status_code == 404
    assert response.json() == {"detail": "Ticket not found"}


def test_invalid_ticket_payload_returns_validation_error() -> None:
    response = client.post("/tickets", json={"customer_name": "Ada"})

    assert response.status_code == 422


@pytest.mark.parametrize(
    "field, value",
    [("status", "in progress"), ("priority", "urgent")],
)
def test_invalid_workflow_values_return_validation_error(field: str, value: str) -> None:
    response = client.post("/tickets", json={**ticket_payload(), field: value})

    assert response.status_code == 422


def test_invalid_status_update_returns_validation_error() -> None:
    create_response = client.post("/tickets", json=ticket_payload())
    ticket_id = create_response.json()["id"]

    response = client.patch(f"/tickets/{ticket_id}", json={"status": "in progress"})

    assert response.status_code == 422
