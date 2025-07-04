-- Migration to add last_trade_at column to players table
-- This supports the streak reset functionality for tracking player trading activity

ALTER TABLE players 
ADD COLUMN IF NOT EXISTS last_trade_at BIGINT DEFAULT NULL;

-- Add an index for efficient querying of inactive players
CREATE INDEX IF NOT EXISTS idx_players_last_trade_at ON players(last_trade_at);

-- Add a comment to document the purpose
COMMENT ON COLUMN players.last_trade_at IS 'Unix timestamp of the players last trade activity, used for streak reset monitoring';