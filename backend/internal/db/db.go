// Package db provides the PostgreSQL database layer for the WildDeck
// server. It wraps a *sql.DB connection pool with typed query methods and a
// migration runner.
package db

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"time"

	_ "github.com/lib/pq" // PostgreSQL driver
)

const (
	maxOpenConns    = 25
	maxIdleConns    = 10
	connMaxLifetime = 30 * time.Minute
	connMaxIdleTime = 5 * time.Minute
)

// DB wraps a *sql.DB and exposes all persistence methods for the application.
type DB struct {
	pool *sql.DB
}

// New opens a PostgreSQL connection pool using the DATABASE_URL environment
// variable (or the provided dsn if non-empty) and verifies connectivity.
func New(ctx context.Context, dsn string) (*DB, error) {
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		return nil, fmt.Errorf("db: DATABASE_URL is not set")
	}

	pool, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("db: sql.Open: %w", err)
	}

	pool.SetMaxOpenConns(maxOpenConns)
	pool.SetMaxIdleConns(maxIdleConns)
	pool.SetConnMaxLifetime(connMaxLifetime)
	pool.SetConnMaxIdleTime(connMaxIdleTime)

	pingCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	if err := pool.PingContext(pingCtx); err != nil {
		_ = pool.Close()
		return nil, fmt.Errorf("db: ping failed: %w", err)
	}

	return &DB{pool: pool}, nil
}

// Close releases all pooled connections.
func (d *DB) Close() error {
	return d.pool.Close()
}

// Pool returns the underlying *sql.DB for callers that need raw access
// (e.g. the migration runner).
func (d *DB) Pool() *sql.DB {
	return d.pool
}
