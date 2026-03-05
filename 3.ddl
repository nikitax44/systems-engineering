CREATE TABLE IF NOT EXISTS messages (
  destination BYTEA NOT NULL,
  payload    BYTEA NOT NULL,
  expires    TIMESTAMP NOT NULL,
  CHECK (octet_length(destination) = 32)
);

CREATE INDEX IF NOT EXISTS idx_messages_dest ON messages (destination);
CREATE INDEX IF NOT EXISTS idx_messages_expire ON messages (expires);
