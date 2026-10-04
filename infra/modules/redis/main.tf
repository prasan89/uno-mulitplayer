# ============================================================
# Redis module
# Provisions: Memorystore for Redis (BASIC tier, Redis 7.0)
#             on private IP with AUTH enabled
# ============================================================

resource "google_redis_instance" "cache" {
  project        = var.project_id
  name           = "wilddeck-redis-${var.environment}"
  region         = var.region
  display_name   = "WildDeck Redis Cache (${var.environment})"

  # BASIC tier — single node (no replication); use STANDARD_HA for production HA
  tier           = "BASIC"
  memory_size_gb = var.redis_memory_gb
  redis_version  = "REDIS_7_0"

  # Restrict to private VPC network — no public IP
  authorized_network = var.network_id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  # Enable AUTH to require a password from clients
  auth_enabled = true

  # Disable in-transit TLS for simplicity; enable if compliance requires it
  transit_encryption_mode = "DISABLED"

  redis_configs = {
    # Evict least-recently-used keys when memory is full (good for a cache workload)
    maxmemory-policy = "allkeys-lru"
  }

  labels = {
    environment = var.environment
    app         = "wilddeck"
  }
}
