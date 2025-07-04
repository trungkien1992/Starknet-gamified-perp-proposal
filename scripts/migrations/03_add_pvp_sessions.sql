-- Create pvp_sessions table for storing PvP match results
CREATE TABLE IF NOT EXISTS pvp_sessions (
    id TEXT PRIMARY KEY,
    player1_id TEXT NOT NULL,
    player2_id TEXT NOT NULL,
    winner_id TEXT,
    status TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP,
    rounds JSONB NOT NULL
); 