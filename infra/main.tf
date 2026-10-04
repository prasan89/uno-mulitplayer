# ============================================================
# Enable required GCP APIs
# ============================================================

# Cloud Run API — for containerised backend service
resource "google_project_service" "cloudrun" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

# Cloud SQL Admin API — for managed PostgreSQL
resource "google_project_service" "sqladmin" {
  project            = var.project_id
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# Memorystore (Redis) API
resource "google_project_service" "redis" {
  project            = var.project_id
  service            = "redis.googleapis.com"
  disable_on_destroy = false
}

# Secret Manager API — for storing database/jwt/redis credentials
resource "google_project_service" "secretmanager" {
  project            = var.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# Cloud Storage API — for Flutter web static hosting
resource "google_project_service" "storage" {
  project            = var.project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

# Compute API — required for VPC, Cloud NAT and VPC connector
resource "google_project_service" "compute" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# Service Networking API — required for private IP peering (Cloud SQL)
resource "google_project_service" "servicenetworking" {
  project            = var.project_id
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

# VPC Access API — required for Cloud Run VPC connector
resource "google_project_service" "vpcaccess" {
  project            = var.project_id
  service            = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}

# ============================================================
# Networking module
# Creates: VPC, subnet, VPC connector, Cloud NAT, private peering
# ============================================================
module "networking" {
  source = "./modules/networking"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  depends_on = [
    google_project_service.compute,
    google_project_service.vpcaccess,
    google_project_service.servicenetworking,
  ]
}

# ============================================================
# Cloud SQL module
# Creates: PostgreSQL 15 instance, database, user
# ============================================================
module "cloud_sql" {
  source = "./modules/cloud-sql"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  db_tier     = var.db_tier
  network_id  = module.networking.vpc_id

  depends_on = [
    google_project_service.sqladmin,
    module.networking,
  ]
}

# ============================================================
# Redis module
# Creates: Memorystore Redis instance on private IP
# ============================================================
module "redis" {
  source = "./modules/redis"

  project_id      = var.project_id
  region          = var.region
  environment     = var.environment
  redis_memory_gb = var.redis_memory_gb
  network_id      = module.networking.vpc_id

  depends_on = [
    google_project_service.redis,
    module.networking,
  ]
}

# ============================================================
# Cloud Run module
# Creates: uno-server service with VPC connector and secrets
# ============================================================
module "cloud_run" {
  source = "./modules/cloud-run"

  project_id        = var.project_id
  region            = var.region
  environment       = var.environment
  min_instances     = var.min_instances
  max_instances     = var.max_instances
  vpc_connector_id  = module.networking.vpc_connector_id
  database_url_secret_id = google_secret_manager_secret.database_url.secret_id
  redis_url_secret_id    = google_secret_manager_secret.redis_url.secret_id
  jwt_secret_secret_id   = google_secret_manager_secret.jwt_secret.secret_id

  depends_on = [
    google_project_service.cloudrun,
    google_secret_manager_secret_version.database_url,
    google_secret_manager_secret_version.redis_url,
    google_secret_manager_secret_version.jwt_secret,
    module.networking,
    module.cloud_sql,
    module.redis,
  ]
}

# ============================================================
# Secret Manager — application secrets
# Placeholder values are set; replace them via the GCP Console
# or with: gcloud secrets versions add <secret-id> --data-file=-
# ============================================================

# Database connection URL secret
resource "google_secret_manager_secret" "database_url" {
  project   = var.project_id
  secret_id = "database-url"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "database_url" {
  secret = google_secret_manager_secret.database_url.id
  # IMPORTANT: replace this placeholder with the real database URL after provisioning
  secret_data = "postgresql://uno:CHANGE_ME@CLOUD_SQL_PRIVATE_IP:5432/uno"

  lifecycle {
    # Prevent Terraform from reverting manually updated secret values
    ignore_changes = [secret_data]
  }
}

# Redis connection URL secret
resource "google_secret_manager_secret" "redis_url" {
  project   = var.project_id
  secret_id = "redis-url"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "redis_url" {
  secret = google_secret_manager_secret.redis_url.id
  # IMPORTANT: replace this placeholder with the real Redis URL after provisioning
  secret_data = "redis://:CHANGE_ME@REDIS_PRIVATE_IP:6379"

  lifecycle {
    ignore_changes = [secret_data]
  }
}

# JWT signing secret
resource "google_secret_manager_secret" "jwt_secret" {
  project   = var.project_id
  secret_id = "jwt-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "jwt_secret" {
  secret = google_secret_manager_secret.jwt_secret.id
  # IMPORTANT: replace this placeholder with a strong random secret
  secret_data = "CHANGE_ME_USE_A_STRONG_RANDOM_SECRET"

  lifecycle {
    ignore_changes = [secret_data]
  }
}

# ============================================================
# Cloud Storage bucket — Flutter web static hosting
# ============================================================

# Public bucket for Flutter web build artifacts
resource "google_storage_bucket" "uno_web" {
  project  = var.project_id
  name     = "${var.project_id}-uno-web"
  location = var.region

  # Uniform bucket-level access (no per-object ACLs)
  uniform_bucket_level_access = true

  # Serve index.html for root and 404 paths (SPA support)
  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }

  # Allow public internet access to bucket objects
  force_destroy = false

  depends_on = [google_project_service.storage]
}

# Make all objects in the bucket publicly readable
resource "google_storage_bucket_iam_member" "uno_web_public" {
  bucket = google_storage_bucket.uno_web.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
