#!/usr/bin/env bash
set -euo pipefail

# seed.sh — Insert test players and matches into the database

DATABASE_URL="${DATABASE_URL:?DATABASE_URL must be set}"

log() { echo "[seed] $*"; }

if ! command -v psql &>/dev/null; then
  echo "ERROR: psql not found in PATH" >&2
  exit 1
fi

log "Seeding 10 test players with random ELO 800-1200..."
psql "${DATABASE_URL}" <<'SQL'
DO $$
DECLARE
  i INTEGER;
  elo_val INTEGER;
BEGIN
  FOR i IN 1..10 LOOP
    elo_val := 800 + floor(random() * 401)::INTEGER;  -- 800 to 1200
    INSERT INTO players (id, username, email, password_hash, elo, created_at, updated_at)
    VALUES (
      gen_random_uuid(),
      'test_player_' || i,
      'test_player_' || i || '@example.com',
      '$2a$10$placeholder_hash',
      elo_val,
      NOW(),
      NOW()
    )
    ON CONFLICT (username) DO NOTHING;
  END LOOP;
END;
$$;
SQL
log "Players seeded."

log "Seeding 3 test matches (waiting, playing, finished)..."
psql "${DATABASE_URL}" <<'SQL'
DO $$
DECLARE
  match_waiting_id UUID := gen_random_uuid();
  match_playing_id UUID := gen_random_uuid();
  match_finished_id UUID := gen_random_uuid();
  player1_id UUID;
  player2_id UUID;
BEGIN
  -- Pick two players for playing/finished matches
  SELECT id INTO player1_id FROM players WHERE username LIKE 'test_player_%' LIMIT 1 OFFSET 0;
  SELECT id INTO player2_id FROM players WHERE username LIKE 'test_player_%' LIMIT 1 OFFSET 1;

  -- Match 1: waiting for players
  INSERT INTO matches (id, status, max_players, created_at, updated_at)
  VALUES (match_waiting_id, 'waiting', 4, NOW(), NOW())
  ON CONFLICT DO NOTHING;

  -- Match 2: currently playing
  INSERT INTO matches (id, status, max_players, started_at, created_at, updated_at)
  VALUES (match_playing_id, 'playing', 4, NOW(), NOW(), NOW())
  ON CONFLICT DO NOTHING;

  IF player1_id IS NOT NULL THEN
    INSERT INTO match_players (match_id, player_id, joined_at)
    VALUES (match_playing_id, player1_id, NOW())
    ON CONFLICT DO NOTHING;
  END IF;

  IF player2_id IS NOT NULL THEN
    INSERT INTO match_players (match_id, player_id, joined_at)
    VALUES (match_playing_id, player2_id, NOW())
    ON CONFLICT DO NOTHING;
  END IF;

  -- Match 3: finished
  INSERT INTO matches (id, status, max_players, started_at, finished_at, created_at, updated_at)
  VALUES (match_finished_id, 'finished', 4, NOW() - INTERVAL '15 minutes', NOW(), NOW() - INTERVAL '15 minutes', NOW())
  ON CONFLICT DO NOTHING;

  IF player1_id IS NOT NULL THEN
    INSERT INTO match_players (match_id, player_id, joined_at, winner)
    VALUES (match_finished_id, player1_id, NOW() - INTERVAL '15 minutes', TRUE)
    ON CONFLICT DO NOTHING;
  END IF;

  IF player2_id IS NOT NULL THEN
    INSERT INTO match_players (match_id, player_id, joined_at, winner)
    VALUES (match_finished_id, player2_id, NOW() - INTERVAL '15 minutes', FALSE)
    ON CONFLICT DO NOTHING;
  END IF;
END;
$$;
SQL
log "Matches seeded."

log "Seed complete."
