# SupportPulse

SupportPulse is a small PostgreSQL customer-support analytics product. It models customers, support agents, tickets, and ticket events, then exposes reporting views for an operations dashboard.

## Run it

```bash
createdb supportpulse
psql supportpulse -f schema.sql
psql supportpulse -f queries.sql
```

`schema.sql` is rerunnable: it rebuilds the demo tables, seed data, indexes, and views. `queries.sql` contains 20 reports covering workload, SLA, response time, resolution time, and customer health.

## Product questions answered

- What work is open, pending, urgent, or unassigned?
- Which customers and plans generate the most support volume?
- How quickly does each agent respond?
- Which categories take longest to resolve?
- How many tickets breach a 60-minute response target?
- What should an operations dashboard show right now?

## Data model

`customers` and `agents` provide account context. `tickets` stores support requests and SLA timestamps. `ticket_events` is an audit trail for workflow history. `ticket_summary` calculates ticket durations, while `daily_support_metrics` provides a dashboard-ready daily rollup.
