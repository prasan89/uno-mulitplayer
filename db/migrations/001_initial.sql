-- 001_initial.sql
-- Initial schema: players, matches, match_players, game_events tables.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- players stores Firebase-authenticated user accounts.
CREATE TABLE IF NOT EXISTS players (
    id             VARCHAR(128)  PRIMARY KEY,           -- Firebase UID
    email          TEXT          UNIQUE NOT NULL,
    display_name   VARCHAR(50)   NOT NULL DEFAULT '',
    avatar_url     TEXT,
    elo_rating     INT           NOT NULL DEFAULT 1000,
    games_played   INT           NOT NULL DEFAULT 0,
    games_won      INT           NOT NULL DEFAULT 0,
    total_score    INT           NOT NULL DEFAULT 0,
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    last_seen_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    is_banned      BOOL          NOT NULL DEFAULT FALSE,
    ban_reason     TEXT
);

-- matches tracks every game session from lobby through completion.
CREATE TABLE IF NOT EXISTS matches (
    id             UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    room_code      VARCHAR(6)    UNIQUE,
    game_mode      VARCHAR(20)   NOT NULL DEFAULT 'classic',
    status         VARCHAR(20)   NOT NULL DEFAULT 'waiting'
                                   CHECK (status IN ('waiting','playing','finished','abandoned')),
    max_players    INT           NOT NULL DEFAULT 4,
    house_rules    JSONB         NOT NULL DEFAULT '{}'::jsonb,
    game_state     JSONB         NOT NULL DEFAULT '{}'::jsonb,
    version        INT           NOT NULL DEFAULT 0,           -- optimistic concurrency
    winner_id      VARCHAR(128)  REFERENCES players(id) ON DELETE SET NULL,
    started_at     TIMESTAMPTZ,
    finished_at    TIMESTAMPTZ,
    abandoned_at   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- match_players is the join table linking players to matches (one row per seat).
CREATE TABLE IF NOT EXISTS match_players (
    match_id         UUID          NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    player_id        VARCHAR(128)  NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    seat_index       INT           NOT NULL,
    is_bot           BOOL          NOT NULL DEFAULT FALSE,
    elo_before       INT,
    elo_after        INT,
    score            INT           NOT NULL DEFAULT 0,
    placement        INT,
    disconnected_at  TIMESTAMPTZ,
    reconnected_at   TIMESTAMPTZ,
    PRIMARY KEY (match_id, player_id)
);

-- game_events is an append-only event log for each match (event sourcing).
CREATE TABLE IF NOT EXISTS game_events (
    id          BIGSERIAL     PRIMARY KEY,
    match_id    UUID          NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    sequence    INT           NOT NULL,
    player_id   VARCHAR(128),
    event_type  VARCHAR(50)   NOT NULL,
    payload     JSONB         NOT NULL DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE (match_id, sequence)
);

-- leaderboard is a materialized view refreshed periodically.
CREATE MATERIALIZED VIEW IF NOT EXISTS leaderboard AS
SELECT
    id,
    display_name,
    avatar_url,
    elo_rating,
    games_played,
    games_won,
    ROUND(games_won::NUMERIC / NULLIF(games_played, 0) * 100, 1) AS win_rate
FROM players
WHERE games_played >= 5
  AND NOT is_banned
ORDER BY elo_rating DESC
LIMIT 100;
