-- Create players table
CREATE TABLE IF NOT EXISTS players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    position_x INTEGER NOT NULL,
    position_y INTEGER NOT NULL,
    health INTEGER NOT NULL,
    score INTEGER NOT NULL,
    level INTEGER NOT NULL,
    experience INTEGER NOT NULL,
    last_move BIGINT,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

-- Create tiles table
CREATE TABLE IF NOT EXISTS tiles (
    id SERIAL PRIMARY KEY,
    position_x INTEGER NOT NULL,
    position_y INTEGER NOT NULL,
    owner_id UUID REFERENCES players(id),
    level INTEGER NOT NULL,
    tile_type TEXT NOT NULL,
    last_updated BIGINT NOT NULL
);

-- Create pvp_matches table
CREATE TABLE IF NOT EXISTS pvp_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player1_id UUID REFERENCES players(id),
    player2_id UUID REFERENCES players(id),
    status TEXT NOT NULL,
    winner UUID REFERENCES players(id),
    created_at BIGINT NOT NULL,
    ended_at BIGINT
);

-- Create streaks table
CREATE TABLE IF NOT EXISTS streaks (
    player_id UUID REFERENCES players(id),
    streak_type TEXT NOT NULL,
    current_streak INTEGER NOT NULL,
    longest_streak INTEGER NOT NULL,
    last_activity BIGINT NOT NULL,
    streak_start BIGINT NOT NULL,
    multiplier DOUBLE PRECISION NOT NULL,
    PRIMARY KEY (player_id, streak_type)
); 