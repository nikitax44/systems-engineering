-- Scrub expired messages
DELETE FROM messages WHERE expires < now();

-- Extract new messages
DELETE FROM messages WHERE destination = $1 RETURNING payload;

-- Insert message
INSERT INTO messages (destination, payload, expires) VALUES ($1, $2, now() + interval '1 week');
