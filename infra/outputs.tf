# Cloud Run service URL (public HTTPS endpoint for the backend API)
output "cloud_run_url" {
  description = "The public HTTPS URL of the Cloud Run wilddeck-server service"
  value       = module.cloud_run.service_url
}

# Cloud SQL connection name (used for Cloud SQL Auth Proxy or private IP)
output "cloud_sql_connection_name" {
  description = "Cloud SQL instance connection name (format: project:region:instance)"
  value       = module.cloud_sql.connection_name
}

# Redis private IP address
output "redis_host" {
  description = "Private IP address of the Memorystore Redis instance"
  value       = module.redis.host
}

# Flutter web bucket public URL
output "web_bucket_url" {
  description = "Public URL of the Cloud Storage bucket serving the Flutter web app"
  value       = "https://storage.googleapis.com/${google_storage_bucket.wilddeck_web.name}"
}
