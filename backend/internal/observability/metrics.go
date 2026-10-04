package observability

import (
	"fmt"
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// Metrics holds all Prometheus instruments registered for the WildDeck server.
// Create exactly one instance via NewMetrics and share it via dependency
// injection. All instruments are registered against a dedicated registry so
// the server does not pollute the global default registry.
type Metrics struct {
	registry *prometheus.Registry

	// ---- WebSocket ----

	// WSConnectionsActive is the number of WebSocket connections currently open.
	WSConnectionsActive prometheus.Gauge

	// WSMessagesReceivedTotal counts inbound WebSocket messages, by type label.
	WSMessagesReceivedTotal *prometheus.CounterVec

	// WSMessagesSentTotal counts outbound WebSocket messages, by type label.
	WSMessagesSentTotal *prometheus.CounterVec

	// WSConnectionDurationSeconds records how long each WebSocket connection
	// is open (seconds).
	WSConnectionDurationSeconds prometheus.Histogram

	// ---- Game ----

	// GamesActive is the number of games currently in progress.
	GamesActive prometheus.Gauge

	// GamesStartedTotal counts games created, labelled by mode (public/private).
	GamesStartedTotal *prometheus.CounterVec

	// GamesFinishedTotal counts finished games, labelled by mode and reason.
	GamesFinishedTotal *prometheus.CounterVec

	// GameDurationSeconds records the wall-clock duration of a game (seconds).
	GameDurationSeconds prometheus.Histogram

	// GameTurnsTotal records the number of turns taken in a single game.
	GameTurnsTotal prometheus.Histogram

	// CardsPlayedTotal counts card-play events, labelled by card_type.
	CardsPlayedTotal *prometheus.CounterVec

	// LastCardCallsTotal counts "LAST CARD!" declarations.
	LastCardCallsTotal prometheus.Counter

	// Draw4ChallengesTotal counts Draw-Four challenge events.
	Draw4ChallengesTotal prometheus.Counter

	// ---- Matchmaking ----

	// MatchmakingQueueSize is the current number of players waiting per mode.
	MatchmakingQueueSize *prometheus.GaugeVec

	// MatchmakingWaitSeconds records how long a player waits in the queue.
	MatchmakingWaitSeconds *prometheus.HistogramVec

	// MatchesCreatedTotal counts matches successfully paired, by mode.
	MatchesCreatedTotal *prometheus.CounterVec

	// ---- Bot ----

	// BotTurnsTotal counts the turns processed by the bot AI, by difficulty.
	BotTurnsTotal *prometheus.CounterVec

	// BotThinkSeconds records bot decision latency, by difficulty.
	BotThinkSeconds *prometheus.HistogramVec

	// BotTakeoversActive is the number of human players currently replaced by bots.
	BotTakeoversActive prometheus.Gauge

	// ---- Database ----

	// DBQueryDurationSeconds records database query latency, by operation.
	DBQueryDurationSeconds *prometheus.HistogramVec

	// DBConnectionsActive is the number of database connections currently in use.
	DBConnectionsActive prometheus.Gauge

	// DBErrorsTotal counts database errors, by operation.
	DBErrorsTotal *prometheus.CounterVec

	// ---- Cache ----

	// CacheHitsTotal counts cache hits, by key_type.
	CacheHitsTotal *prometheus.CounterVec

	// CacheMissesTotal counts cache misses, by key_type.
	CacheMissesTotal *prometheus.CounterVec

	// CacheOperationSeconds records cache operation latency, by operation.
	CacheOperationSeconds *prometheus.HistogramVec

	// ---- HTTP ----

	// HTTPRequestsTotal counts HTTP requests, labelled by method, path, and
	// status code.
	HTTPRequestsTotal *prometheus.CounterVec

	// HTTPRequestDurationSeconds records HTTP handler latency.
	HTTPRequestDurationSeconds prometheus.Histogram
}

// NewMetrics registers all instruments and returns the populated Metrics struct.
// Call this once at startup and share the result.
func NewMetrics() (*Metrics, error) {
	reg := prometheus.NewRegistry()

	// Use promauto with the custom registry so we never touch the global one.
	factory := promauto.With(reg)

	m := &Metrics{registry: reg}

	// ---- WebSocket ----
	m.WSConnectionsActive = factory.NewGauge(prometheus.GaugeOpts{
		Name: "ws_connections_active",
		Help: "Number of WebSocket connections currently open.",
	})

	m.WSMessagesReceivedTotal = factory.NewCounterVec(prometheus.CounterOpts{
		Name: "ws_messages_received_total",
		Help: "Total number of inbound WebSocket messages.",
	}, []string{"type"})

	m.WSMessagesSentTotal = factory.NewCounterVec(prometheus.CounterOpts{
		Name: "ws_messages_sent_total",
		Help: "Total number of outbound WebSocket messages.",
	}, []string{"type"})

	m.WSConnectionDurationSeconds = factory.NewHistogram(prometheus.HistogramOpts{
		Name:    "ws_connection_duration_seconds",
		Help:    "Duration of WebSocket connections in seconds.",
		Buckets: prometheus.ExponentialBuckets(1, 2, 12), // 1s … ~1h
	})

	// ---- Game ----
	m.GamesActive = factory.NewGauge(prometheus.GaugeOpts{
		Name: "games_active",
		Help: "Number of games currently in progress.",
	})

	m.GamesStartedTotal = factory.NewCounterVec(prometheus.CounterOpts{
		Name: "games_started_total",
		Help: "Total number of games started.",
	}, []string{"mode"})

	m.GamesFinishedTotal = factory.NewCounterVec(prometheus.CounterOpts{
		Name: "games_finished_total",
		Help: "Total number of games finished.",
	}, []string{"mode", "reason"})

	m.GameDurationSeconds = factory.NewHistogram(prometheus.HistogramOpts{
		Name:    "game_duration_seconds",
		Help:    "Wall-clock duration of a game in seconds.",
		Buckets: prometheus.ExponentialBuckets(60, 2, 10), // 1 min … ~17 h
	})

	m.GameTurnsTotal = factory.NewHistogram(prometheus.HistogramOpts{
		Name:    "game_turns_total",
		Help:    "Number of turns taken in a single game.",
		Buckets: prometheus.LinearBuckets(10, 10, 20), // 10 … 210
	})

	m.CardsPlayedTotal = factory.NewCounterVec(prometheus.CounterOpts{
		Name: "cards_played_total",
		Help: "Total number of cards played, labelled by card type.",
	}, []string{"card_type"})

	m.LastCardCallsTotal = factory.NewCounter(prometheus.CounterOpts{
		Name: "last_card_calls_total",
		Help: "Total number of Last Card declarations made.",
	})

	m.Draw4ChallengesTotal = factory.NewCounter(prometheus.CounterOpts{
		Name: "draw4_challenges_total",
		Help: "Total number of Draw-Four challenges made.",
	})

	// ---- Matchmaking ----
	m.MatchmakingQueueSize = factory.NewGaugeVec(prometheus.GaugeOpts{
		Name: "matchmaking_queue_size",
		Help: "Current number of players waiting in the matchmaking queue.",
	}, []string{"mode"})

	m.MatchmakingWaitSeconds = factory.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "matchmaking_wait_seconds",
		Help:    "Time players spend waiting in the matchmaking queue.",
		Buckets: prometheus.ExponentialBuckets(1, 2, 8), // 1s … 128s
	}, []string{"mode"})

	m.MatchesCreatedTotal = factory.NewCounterVec(prometheus.CounterOpts{
		Name: "matches_created_total",
		Help: "Total number of matches successfully created by matchmaking.",
	}, []string{"mode"})

	// ---- Bot ----
	m.BotTurnsTotal = factory.NewCounterVec(prometheus.CounterOpts{
		Name: "bot_turns_total",
		Help: "Total number of turns processed by the bot AI.",
	}, []string{"difficulty"})

	m.BotThinkSeconds = factory.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "bot_think_seconds",
		Help:    "Latency of the bot decision function.",
		Buckets: prometheus.ExponentialBuckets(0.001, 2, 10), // 1 ms … ~1s
	}, []string{"difficulty"})

	m.BotTakeoversActive = factory.NewGauge(prometheus.GaugeOpts{
		Name: "bot_takeovers_active",
		Help: "Number of human players currently replaced by a bot.",
	})

	// ---- Database ----
	m.DBQueryDurationSeconds = factory.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "db_query_duration_seconds",
		Help:    "Database query latency in seconds.",
		Buckets: prometheus.ExponentialBuckets(0.001, 2, 10), // 1 ms … ~1s
	}, []string{"operation"})

	m.DBConnectionsActive = factory.NewGauge(prometheus.GaugeOpts{
		Name: "db_connections_active",
		Help: "Number of database connections currently in use.",
	})

	m.DBErrorsTotal = factory.NewCounterVec(prometheus.CounterOpts{
		Name: "db_errors_total",
		Help: "Total number of database errors.",
	}, []string{"operation"})

	// ---- Cache ----
	m.CacheHitsTotal = factory.NewCounterVec(prometheus.CounterOpts{
		Name: "cache_hits_total",
		Help: "Total number of cache hits.",
	}, []string{"key_type"})

	m.CacheMissesTotal = factory.NewCounterVec(prometheus.CounterOpts{
		Name: "cache_misses_total",
		Help: "Total number of cache misses.",
	}, []string{"key_type"})

	m.CacheOperationSeconds = factory.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "cache_operation_seconds",
		Help:    "Cache operation latency in seconds.",
		Buckets: prometheus.ExponentialBuckets(0.0001, 2, 12), // 100µs … ~400ms
	}, []string{"operation"})

	// ---- HTTP ----
	m.HTTPRequestsTotal = factory.NewCounterVec(prometheus.CounterOpts{
		Name: "http_requests_total",
		Help: "Total number of HTTP requests.",
	}, []string{"method", "path", "status"})

	m.HTTPRequestDurationSeconds = factory.NewHistogram(prometheus.HistogramOpts{
		Name:    "http_request_duration_seconds",
		Help:    "HTTP request latency in seconds.",
		Buckets: prometheus.DefBuckets,
	})

	return m, nil
}

// Registry returns the Prometheus registry that backs this Metrics instance.
// Pass it to promhttp.HandlerFor when starting the metrics HTTP server.
func (m *Metrics) Registry() *prometheus.Registry {
	return m.registry
}

// StartMetricsServer starts a dedicated HTTP server on addr (e.g. ":9090")
// that serves the Prometheus /metrics endpoint. It blocks until the server
// exits and sends any error to the returned channel.
//
// The caller should wait on the error channel and log the result.
//
//	go func() {
//	    if err := <-m.StartMetricsServer(":9090"); err != nil {
//	        logger.Error("metrics server error", zap.Error(err))
//	    }
//	}()
func (m *Metrics) StartMetricsServer(addr string) <-chan error {
	errCh := make(chan error, 1)

	mux := http.NewServeMux()
	mux.Handle("/metrics", promhttp.HandlerFor(m.registry, promhttp.HandlerOpts{
		EnableOpenMetrics: true,
	}))

	srv := &http.Server{
		Addr:    addr,
		Handler: mux,
	}

	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			errCh <- fmt.Errorf("observability: metrics server on %s: %w", addr, err)
		}
		close(errCh)
	}()

	return errCh
}
