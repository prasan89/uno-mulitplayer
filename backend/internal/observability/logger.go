// Package observability provides logging, metrics, and health-check
// infrastructure for the UNO multiplayer server.
package observability

import (
	"fmt"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// InitLogger creates a *zap.Logger configured for the given environment.
//
// env == "production" → JSON format, suitable for log aggregators.
// Any other value    → coloured console format for local development.
//
// level is a zap level string: "debug", "info", "warn", "error".
// An empty string defaults to "info".
func InitLogger(level, env string) (*zap.Logger, error) {
	lvl, err := parseLevel(level)
	if err != nil {
		return nil, err
	}

	var cfg zap.Config
	if env == "production" {
		cfg = zap.NewProductionConfig()
		cfg.EncoderConfig.TimeKey = "ts"
		cfg.EncoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
	} else {
		cfg = zap.NewDevelopmentConfig()
		cfg.EncoderConfig.EncodeLevel = zapcore.CapitalColorLevelEncoder
	}

	cfg.Level = zap.NewAtomicLevelAt(lvl)

	logger, err := cfg.Build(
		zap.AddCallerSkip(0),
		zap.AddStacktrace(zapcore.ErrorLevel),
	)
	if err != nil {
		return nil, fmt.Errorf("observability: build logger: %w", err)
	}

	return logger, nil
}

// parseLevel converts the string representation of a zap level to a
// zapcore.Level value. An empty string is treated as InfoLevel.
func parseLevel(s string) (zapcore.Level, error) {
	if s == "" {
		return zapcore.InfoLevel, nil
	}
	var lvl zapcore.Level
	if err := lvl.UnmarshalText([]byte(s)); err != nil {
		return 0, fmt.Errorf("observability: invalid log level %q: %w", s, err)
	}
	return lvl, nil
}

// GameActionFields returns the standard set of zap fields that must appear in
// every game-action log entry. Pass zero values for fields that are not
// applicable to a given call site; they will still be emitted so log
// aggregators can index on a consistent schema.
//
// Fields included: game_id, player_id, action, card_id, sequence, duration_ms.
// Fields intentionally omitted: card hand contents, JWT tokens, passwords.
func GameActionFields(
	gameID, playerID, action, cardID string,
	sequence uint64,
	durationMS int64,
	err error,
) []zap.Field {
	fields := []zap.Field{
		zap.String("game_id", gameID),
		zap.String("player_id", playerID),
		zap.String("action", action),
		zap.String("card_id", cardID),
		zap.Uint64("sequence", sequence),
		zap.Int64("duration_ms", durationMS),
	}
	if err != nil {
		fields = append(fields, zap.Error(err))
	}
	return fields
}

// Log-level guidance (documented here so call sites remain consistent):
//
//	DEBUG – card plays, bot decisions, per-turn state transitions.
//	INFO  – game start / end / join / leave, matchmaking events.
//	WARN  – player reconnects, rate-limit hits, suspicious sequences.
//	ERROR – DB failures, WebSocket errors, recovered panics.
//
// Never log: card hands, JWT tokens, passwords.
