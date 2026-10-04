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

variable "redis_memory_gb" {
  description = "Redis memory size in GB"
  type        = number
}

variable "network_id" {
  description = "VPC network self-link for private IP"
  type        = string
}

# ---- Outputs ---------------------------------------------------

output "host" {
  description = "Private IP address of the Redis instance"
  value       = google_redis_instance.cache.host
}

output "port" {
  description = "Port of the Redis instance"
  value       = google_redis_instance.cache.port
}

output "auth_string" {
  description = "AUTH string for the Redis instance (sensitive)"
  value       = google_redis_instance.cache.auth_string
  sensitive   = true
}
