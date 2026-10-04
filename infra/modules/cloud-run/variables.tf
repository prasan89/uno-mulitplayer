variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "min_instances" {
  description = "Minimum number of Cloud Run instances"
  type        = number
}

variable "max_instances" {
  description = "Maximum number of Cloud Run instances"
  type        = number
}

variable "vpc_connector_id" {
  description = "ID of the Serverless VPC Access connector"
  type        = string
}

variable "database_url_secret_id" {
  description = "Secret Manager secret ID for the database URL"
  type        = string
}

variable "redis_url_secret_id" {
  description = "Secret Manager secret ID for the Redis URL"
  type        = string
}

variable "jwt_secret_secret_id" {
  description = "Secret Manager secret ID for the JWT signing secret"
  type        = string
}

# ---- Outputs ---------------------------------------------------

output "service_url" {
  description = "Public HTTPS URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.wilddeck_server.uri
}

output "service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_v2_service.wilddeck_server.name
}

output "service_account_email" {
  description = "Email of the Cloud Run service account"
  value       = google_service_account.cloud_run_sa.email
}
