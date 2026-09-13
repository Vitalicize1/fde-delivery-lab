-- SupportPulse: a small customer-support analytics product.
-- Run this file to create a fresh local demo database.

DROP VIEW IF EXISTS daily_support_metrics;
DROP VIEW IF EXISTS ticket_summary;
DROP TABLE IF EXISTS ticket_events;
DROP TABLE IF EXISTS tickets;
DROP TABLE IF EXISTS agents;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL, email TEXT UNIQUE NOT NULL,
    plan TEXT NOT NULL CHECK (plan IN ('free', 'pro', 'business')),
    city TEXT, created_at DATE NOT NULL
);

CREATE TABLE agents (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    team TEXT NOT NULL CHECK (team IN ('technical', 'billing', 'account')),
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE tickets (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    agent_id INTEGER REFERENCES agents(id), subject TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('access', 'account', 'bug', 'billing', 'how_to', 'performance')),
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'pending', 'closed')),
    priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    created_at TIMESTAMP NOT NULL, first_response_at TIMESTAMP, resolved_at TIMESTAMP,
    CHECK (resolved_at IS NULL OR resolved_at >= created_at),
    CHECK (first_response_at IS NULL OR first_response_at >= created_at)
);

CREATE TABLE ticket_events (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id INTEGER NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN ('created', 'assigned', 'replied', 'status_changed', 'resolved')),
    event_at TIMESTAMP NOT NULL, note TEXT
);

INSERT INTO customers (name, email, plan, city, created_at) VALUES
('Ada Lovelace', 'ada@example.com', 'business', 'London', '2025-01-12'),
('Grace Hopper', 'grace@example.com', 'pro', 'New York', '2025-02-03'),
('Linus Torvalds', 'linus@example.com', 'business', 'Helsinki', '2025-02-18'),
('Margaret Hamilton', 'margaret@example.com', 'pro', 'Boston', '2025-03-09'),
('Katherine Johnson', 'katherine@example.com', 'free', 'Hampton', '2025-03-22'),
('James Gosling', 'james@example.com', 'pro', 'Calgary', '2025-04-05');

INSERT INTO agents (name, team) VALUES
('Maya Chen', 'technical'), ('Noah Williams', 'billing'), ('Priya Shah', 'account');

INSERT INTO tickets (customer_id, agent_id, subject, category, status, priority, created_at, first_response_at, resolved_at) VALUES
(1,1,'Cannot sign in','access','closed','urgent','2025-05-01 09:10','2025-05-01 09:24','2025-05-01 10:05'),
(1,3,'Invite a new teammate','how_to','closed','normal','2025-05-02 14:00','2025-05-02 15:10','2025-05-02 16:20'),
(2,1,'Report export is slow','performance','open','high','2025-05-03 08:30','2025-05-03 09:00',NULL),
(2,2,'Duplicate invoice','billing','closed','high','2025-05-04 11:45','2025-05-04 12:05','2025-05-05 09:30'),
(3,1,'API access request','access','pending','low','2025-05-05 16:15','2025-05-06 08:40',NULL),
(3,1,'Webhook returns 500','bug','closed','urgent','2025-05-06 10:00','2025-05-06 10:12','2025-05-07 13:00'),
(4,3,'Change account owner','account','open','normal','2025-05-07 13:20',NULL,NULL),
(4,1,'Dashboard does not load','bug','closed','high','2025-05-08 07:50','2025-05-08 08:05','2025-05-08 11:45'),
(5,NULL,'How do I export data?','how_to','open','low','2025-05-09 17:30',NULL,NULL),
(5,2,'Unexpected renewal charge','billing','pending','high','2025-05-10 09:00','2025-05-10 09:45',NULL),
(6,1,'SDK installation fails','bug','closed','normal','2025-05-11 12:10','2025-05-11 13:00','2025-05-12 10:10'),
(6,3,'Add a billing contact','account','closed','low','2025-05-12 15:40','2025-05-12 16:05','2025-05-12 16:30');

INSERT INTO ticket_events (ticket_id, event_type, event_at, note) VALUES
(1, 'created', '2025-05-01 09:10', 'Customer opened ticket'),
(1, 'assigned', '2025-05-01 09:18', 'Assigned to Maya Chen'),
(1, 'replied', '2025-05-01 09:24', 'Shared sign-in recovery steps'),
(1, 'resolved', '2025-05-01 10:05', 'Customer confirmed access');

CREATE INDEX tickets_status_idx ON tickets(status);
CREATE INDEX tickets_created_at_idx ON tickets(created_at);
CREATE INDEX tickets_customer_id_idx ON tickets(customer_id);

CREATE VIEW ticket_summary AS
SELECT t.id, t.subject, t.category, t.status, t.priority, c.name AS customer,
       c.plan, a.name AS agent,
       EXTRACT(EPOCH FROM (t.first_response_at - t.created_at)) / 60 AS first_response_minutes,
       EXTRACT(EPOCH FROM (t.resolved_at - t.created_at)) / 3600 AS resolution_hours
FROM tickets t JOIN customers c ON c.id = t.customer_id LEFT JOIN agents a ON a.id = t.agent_id;

CREATE VIEW daily_support_metrics AS
SELECT tickets.created_at::date AS day, COUNT(*) AS tickets_created,
       COUNT(*) FILTER (WHERE ticket_summary.status = 'closed') AS tickets_closed,
       ROUND(AVG(first_response_minutes)::numeric, 1) AS avg_first_response_minutes,
       ROUND(AVG(resolution_hours) FILTER (WHERE ticket_summary.status = 'closed')::numeric, 1) AS avg_resolution_hours
FROM ticket_summary JOIN tickets USING (id)
GROUP BY tickets.created_at::date;
