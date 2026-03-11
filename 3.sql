-- Scrub expired users
DELETE FROM users WHERE expires < now();

-- Extract new messages
DELETE FROM messages WHERE destination = $1 RETURNING payload;
UPDATE users SET expires = now() + interval '1 week' WHERE id = $1;

-- Insert message
INSERT INTO messages (destination, payload) SELECT id, $2 FROM users WHERE id = $1;
