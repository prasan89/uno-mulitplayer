# ============================================================
# Cloud SQL module
# Provisions: PostgreSQL 15 instance (private IP, HA),
#             database "wilddeck", user "wilddeck"
# ============================================================

# ---- Cloud SQL Instance ----------------------------------------

resource "google_sql_database_instance" "postgres" {
  project          = var.project_id
  name             = "wilddeck-postgres-${var.environment}"
  region           = var.region
  database_version = "POSTGRES_15"

  # Prevent accidental deletion of production database
  deletion_protection = true

  settings {
    tier              = var.db_tier
    availability_type = "REGIONAL" # High-availability with failover replica

    # Private IP only — no public IP exposure
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.network_id
      enable_private_path_for_google_cloud_services = true
    }

    # Daily automated backups at 2:00 AM UTC
    backup_configuration {
      enabled                        = true
      start_time                     = "02:00"
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7 # keep one week of daily backups
      }
    }

    # Maintenance window (Sunday 3 AM UTC — lowest expected traffic)
    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }

    database_flags {
      name  = "max_connections"
      value = "100"
    }
  }

  depends_on = [var.network_id]
}

# ---- Database --------------------------------------------------

# Application database
resource "google_sql_database" "wilddeck" {
  project  = var.project_id
  instance = google_sql_database_instance.postgres.name
  name     = "wilddeck"
}

# ---- Database User ---------------------------------------------

# Application user — password managed via Secret Manager
resource "google_sql_user" "wilddeck" {
  project  = var.project_id
  instance = google_sql_database_instance.postgres.name
  name     = "wilddeck"
  # Password is intentionally set to a placeholder; update via:
  #   gcloud sql users set-password wilddeck --instance=<name> --password=<strong-pw>
  password = "CHANGE_ME_SET_VIA_GCLOUD_OR_CONSOLE"
}
