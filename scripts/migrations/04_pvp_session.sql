CREATE TABLE IF NOT EXISTS pvp_sessions (
    id SERIAL PRIMARY KEY,
    player_a TEXT NOT NULL,
    player_b TEXT NOT NULL,
    start_block BIGINT NOT NULL,
    result TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
); 