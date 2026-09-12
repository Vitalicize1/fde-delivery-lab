CREATE TABLE customers (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    city TEXT
);

CREATE TABLE tickets (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    subject TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open',
    priority TEXT NOT NULL DEFAULT 'normal',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO customers (name, email, city) VALUES
    ('Ada Lovelace', 'ada@example.com', 'London'),
    ('Grace Hopper', 'grace@example.com', 'New York'),
    ('Linus Torvalds', 'linus@example.com', 'Helsinki');

INSERT INTO tickets (customer_id, subject, status, priority) VALUES
    (1, 'Cannot sign in', 'open', 'high'),
    (1, 'Password reset question', 'closed', 'normal'),
    (2, 'Report export is slow', 'open', 'normal'),
    (3, 'API access request', 'pending', 'low');
