-- scripts/migrations/V1__Create_initial_tables.sql
--
-- This is our first versioned migration for Flyway.
-- Flyway will run this file exactly once to set up our initial schema.

-- Stores user identity and wallet information
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Records every trade executed by a user
CREATE TABLE trades (
    trade_id UUID PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(user_id),
    pnl_percent DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ledger of all Ink transactions
CREATE TABLE ink_ledger (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(user_id),
    ink_delta INTEGER NOT NULL,
    source_trade_id UUID REFERENCES trades(trade_id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Stores ownership and Ink levels for map tiles.
CREATE TABLE map_tiles (
    id SERIAL PRIMARY KEY,
    owner_user_id TEXT UNIQUE,
    x INTEGER NOT NULL,
    y INTEGER NOT NULL,
    ink_level BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
