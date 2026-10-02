"""A small in-memory customer support ticket API."""

from typing import Dict, List, Literal, Optional

from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field


TicketPriority = Literal["low", "normal", "high"]
TicketStatus = Literal["open", "pending", "closed"]


class TicketCreate(BaseModel):
    """Fields required when creating a support ticket."""

    customer_name: str = Field(..., min_length=1, description="Name of the customer")
    subject: str = Field(..., min_length=1, description="Short description of the issue")
    description: str = Field(..., min_length=1, description="Full description of the issue")
    priority: TicketPriority = Field(default="normal", description="Ticket priority")
    status: TicketStatus = Field(default="open", description="Initial ticket status")
    owner: Optional[str] = Field(default=None, min_length=1, description="Assigned support owner")


class Ticket(TicketCreate):
    """A support ticket returned by the API, including its generated ID."""

    id: int
class TicketUpdate(BaseModel):
    """Optional fields that can be changed on an existing ticket."""

    customer_name: Optional[str] = Field(default=None, min_length=1)
    subject: Optional[str] = Field(default=None, min_length=1)
    description: Optional[str] = Field(default=None, min_length=1)
    priority: Optional[TicketPriority] = Field(default=None, description="Ticket priority")
    status: Optional[TicketStatus] = Field(default=None, description="Ticket status")
    owner: Optional[str] = Field(default=None, min_length=1, description="Assigned support owner")


app = FastAPI(
    title="Customer Operations API",
    description="A beginner-friendly API for managing customer support tickets.",
    version="1.0.0",
)

# This dictionary is intentionally temporary. Restarting the server clears it.
tickets: Dict[int, Ticket] = {}
next_ticket_id = 1


@app.get("/", tags=["health"])
def read_root() -> dict[str, str]:
    """Return a small health message and point to the API documentation."""

    return {"message": "Customer Operations API is running", "docs": "/docs"}


@app.post("/tickets", response_model=Ticket, status_code=status.HTTP_201_CREATED, tags=["tickets"])
def create_ticket(ticket_data: TicketCreate) -> Ticket:
    """Create a new support ticket."""

    global next_ticket_id

    ticket = Ticket(id=next_ticket_id, **ticket_data.model_dump())
    tickets[ticket.id] = ticket
    next_ticket_id += 1
    return ticket


@app.get("/tickets", response_model=List[Ticket], tags=["tickets"])
def list_tickets() -> List[Ticket]:
    """Return all support tickets."""

    return list(tickets.values())


@app.get("/tickets/{ticket_id}", response_model=Ticket, tags=["tickets"])
def get_ticket(ticket_id: int) -> Ticket:
    """Return one ticket by ID."""

    ticket = tickets.get(ticket_id)
    if ticket is None:
        raise HTTPException(status_code=404, detail="Ticket not found")
    return ticket


@app.patch("/tickets/{ticket_id}", response_model=Ticket, tags=["tickets"])
def update_ticket(ticket_id: int, ticket_data: TicketUpdate) -> Ticket:
    """Update any supplied fields on an existing ticket."""

    ticket = tickets.get(ticket_id)
    if ticket is None:
        raise HTTPException(status_code=404, detail="Ticket not found")

    updated_fields = ticket_data.model_dump(exclude_unset=True)
    updated_ticket = ticket.model_copy(update=updated_fields)
    tickets[ticket_id] = updated_ticket
    return updated_ticket


@app.delete("/tickets/{ticket_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["tickets"])
def delete_ticket(ticket_id: int) -> None:
    """Delete an existing ticket."""

    if ticket_id not in tickets:
        raise HTTPException(status_code=404, detail="Ticket not found")
    del tickets[ticket_id]
