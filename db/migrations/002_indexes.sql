-- 002_indexes.sql
-- Performance indexes for common query patterns.

-- Partial index: room_code lookups only matter when the code is set.
CREATE UNIQUE INDEX IF NOT EXISTS idx_matches_room_code
    ON matches (room_code)
    WHERE room_code IS NOT NULL;

-- Status-based filtering (lobby list, stale-match cleanup).
CREATE INDEX IF NOT EXISTS idx_matches_status
    ON matches (status);

-- Look up all matches a specific player has participated in.
CREATE INDEX IF NOT EXISTS idx_match_players_player
    ON match_players (player_id);

-- Event replay: fetch ordered events for a match efficiently.
CREATE INDEX IF NOT EXISTS idx_game_events_match
    ON game_events (match_id, sequence);

-- Leaderboard ordering without a full table scan.
CREATE INDEX IF NOT EXISTS idx_players_elo
    ON players (elo_rating DESC);

-- Unique index backing the leaderboard materialized view's ORDER BY.
CREATE UNIQUE INDEX IF NOT EXISTS idx_leaderboard_id
    ON leaderboard (id);
