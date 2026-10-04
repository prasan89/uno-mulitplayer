# GCP project ID where all resources will be deployed (required)
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

# GCP region for resource deployment
variable "region" {
  description = "The GCP region for resource deployment"
  type        = string
  default     = "us-central1"
}

# Deployment environment tag (e.g. production, staging, dev)
variable "environment" {
  description = "Deployment environment (e.g. production, staging, dev)"
  type        = string
  default     = "production"
}

# Minimum number of Cloud Run instances to keep warm
variable "min_instances" {
  description = "Minimum number of Cloud Run instances"
  type        = number
  default     = 1
}

# Maximum number of Cloud Run instances that can scale up to
variable "max_instances" {
  description = "Maximum number of Cloud Run instances"
  type        = number
  default     = 10
}

# Cloud SQL machine tier
variable "db_tier" {
  description = "Cloud SQL instance tier (e.g. db-g1-small, db-n1-standard-1)"
  type        = string
  default     = "db-g1-small"
}

# Memorystore Redis memory size in GB
variable "redis_memory_gb" {
  description = "Redis Memorystore memory size in GB"
  type        = number
  default     = 1
}

# Optional custom domain name for the application
variable "domain_name" {
  description = "Custom domain name for the application (leave empty if not using a custom domain)"
  type        = string
  default     = ""
}
