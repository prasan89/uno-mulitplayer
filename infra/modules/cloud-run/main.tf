# ============================================================
# Cloud Run module
# Provisions: uno-server Cloud Run service
#   - Public (unauthenticated) HTTPS endpoint
#   - Secrets injected as environment variables from Secret Manager
#   - Connected to VPC via connector for private resource access
# ============================================================

# ---- Service Account for Cloud Run ----------------------------

# Dedicated service account with least-privilege access
resource "google_service_account" "cloud_run_sa" {
  project      = var.project_id
  account_id   = "uno-server-sa"
  display_name = "UNO Server Cloud Run Service Account"
}

# Allow the service account to read secrets from Secret Manager
resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# ---- Cloud Run Service ----------------------------------------

resource "google_cloud_run_v2_service" "uno_server" {
  project  = var.project_id
  name     = "uno-server"
  location = var.region

  # Allow direct VPC egress through the connector
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run_sa.email

    # Scaling configuration
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    # VPC connector — routes traffic to private resources (Cloud SQL, Redis)
    vpc_access {
      connector = var.vpc_connector_id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    # Container specification
    containers {
      # Image built and pushed to GCR by the CI/CD pipeline
      image = "gcr.io/${var.project_id}/uno-server:latest"

      # Resource limits per container instance
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
        # Allow CPU to be throttled when not processing requests (saves cost)
        cpu_idle = true
      }

      # ---- Environment variables from Secret Manager ----------

      # Database connection URL
      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = var.database_url_secret_id
            version = "latest"
          }
        }
      }

      # Redis connection URL
      env {
        name = "REDIS_URL"
        value_source {
          secret_key_ref {
            secret  = var.redis_url_secret_id
            version = "latest"
          }
        }
      }

      # JWT signing secret
      env {
        name = "JWT_SECRET"
        value_source {
          secret_key_ref {
            secret  = var.jwt_secret_secret_id
            version = "latest"
          }
        }
      }

      # Expose the HTTP port Cloud Run routes traffic to
      ports {
        name           = "h2c"    # HTTP/2 cleartext (WebSocket-compatible)
        container_port = 8080
      }
    }

    # Max request duration (long-lived for WebSocket game sessions)
    timeout = "300s"

    # Max concurrent requests per instance before a new one is started
    max_instance_request_concurrency = 80
  }

  labels = {
    environment = var.environment
    app         = "uno"
  }
}

# ---- IAM — allow unauthenticated (public) access --------------

# The UNO API is a public endpoint; Cloud Run IAM must allow allUsers
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.uno_server.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
