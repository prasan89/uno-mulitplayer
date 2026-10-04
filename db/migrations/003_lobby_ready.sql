-- 003_lobby_ready.sql
-- Adds lobby ready-state tracking to match_players.
-- Players can toggle ready/unready while the match is in 'waiting' status.

ALTER TABLE match_players
    ADD COLUMN IF NOT EXISTS is_ready BOOL NOT NULL DEFAULT FALSE;

-- Index for fast lobby queries (fetch all players + ready state for a match).
CREATE INDEX IF NOT EXISTS idx_match_players_match_ready
    ON match_players (match_id, is_ready);
