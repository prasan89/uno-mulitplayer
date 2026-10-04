package db

import (
	"context"
	"database/sql"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

// schemaVersionsTable is the table used to track applied migrations.
const schemaVersionsTable = `
CREATE TABLE IF NOT EXISTS schema_migrations (
    filename   TEXT      PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
)`

// Migrate reads all *.sql files from migrationsDir in lexicographic order and
// executes each one exactly once (idempotent).  It creates a schema_migrations
// tracking table on first run.
func Migrate(ctx context.Context, pool *sql.DB, migrationsDir string) error {
	// Ensure the migrations tracking table exists.
	if _, err := pool.ExecContext(ctx, schemaVersionsTable); err != nil {
		return fmt.Errorf("db.Migrate: create schema_migrations: %w", err)
	}

	// Collect all SQL files.
	files, err := collectSQLFiles(migrationsDir)
	if err != nil {
		return fmt.Errorf("db.Migrate: collect files: %w", err)
	}
	sort.Strings(files)

	for _, path := range files {
		filename := filepath.Base(path)

		// Check if already applied.
		var existing string
		err := pool.QueryRowContext(ctx,
			`SELECT filename FROM schema_migrations WHERE filename = $1`, filename,
		).Scan(&existing)
		if err == nil {
			// Already applied — skip.
			continue
		}
		if err != sql.ErrNoRows {
			return fmt.Errorf("db.Migrate: check %s: %w", filename, err)
		}

		// Read migration file.
		content, err := os.ReadFile(path)
		if err != nil {
			return fmt.Errorf("db.Migrate: read %s: %w", filename, err)
		}

		// Execute inside a transaction so a failure leaves the DB clean.
		tx, err := pool.BeginTx(ctx, nil)
		if err != nil {
			return fmt.Errorf("db.Migrate: begin tx for %s: %w", filename, err)
		}

		if _, err := tx.ExecContext(ctx, string(content)); err != nil {
			_ = tx.Rollback()
			return fmt.Errorf("db.Migrate: exec %s: %w", filename, err)
		}

		if _, err := tx.ExecContext(ctx,
			`INSERT INTO schema_migrations (filename) VALUES ($1)`, filename,
		); err != nil {
			_ = tx.Rollback()
			return fmt.Errorf("db.Migrate: record %s: %w", filename, err)
		}

		if err := tx.Commit(); err != nil {
			return fmt.Errorf("db.Migrate: commit %s: %w", filename, err)
		}
	}
	return nil
}

// collectSQLFiles returns absolute paths of every *.sql file directly inside
// migrationsDir (non-recursive).
func collectSQLFiles(dir string) ([]string, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}
	var out []string
	for _, e := range entries {
		if e.Type()&fs.ModeType == 0 && strings.HasSuffix(e.Name(), ".sql") {
			out = append(out, filepath.Join(dir, e.Name()))
		}
	}
	return out, nil
}
