CREATE TABLE IF NOT EXISTS users (
    id     BYTEA PRIMARY KEY,
    s_pk   BYTEA NOT NULL,
    c_pk   BYTEA NOT NULL,
    expires TIMESTAMP NOT NULL,
    CONSTRAINT chk_id_length CHECK (octet_length(id) = 32)
);

CREATE TABLE messages (
    destination BYTEA NOT NULL,
    payload     BYTEA NOT NULL,
    CONSTRAINT fk_destination
        FOREIGN KEY (destination) REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_users_expire ON users (expires);
