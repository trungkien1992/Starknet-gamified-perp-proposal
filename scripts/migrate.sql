CREATE TABLE IF NOT EXISTS trades (
  trade_id UUID PRIMARY KEY,
  user_addr TEXT NOT NULL,
  pnl_usd INTEGER NOT NULL,
  leverage_x INTEGER NOT NULL,
  ts_unix BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS ink_ledger (
  id SERIAL PRIMARY KEY,
  trade_id UUID REFERENCES trades(trade_id),
  ink_delta INTEGER NOT NULL,
  ts TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tiles (
  id SERIAL PRIMARY KEY,
  owner_addr TEXT,
  x INTEGER,
  y INTEGER
);

ALTER TABLE tiles ADD CONSTRAINT tiles_xy_unique UNIQUE (x, y);

CREATE TABLE IF NOT EXISTS user_streaks (
  user_addr TEXT PRIMARY KEY,
  streak INTEGER NOT NULL CHECK (streak >= 0)
);
