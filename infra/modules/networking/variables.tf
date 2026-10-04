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

# ---- Outputs ---------------------------------------------------

output "vpc_id" {
  description = "Self-link of the VPC network"
  value       = google_compute_network.uno_vpc.id
}

output "vpc_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.uno_vpc.name
}

output "subnet_id" {
  description = "Self-link of the regional subnet"
  value       = google_compute_subnetwork.uno_subnet.id
}

output "vpc_connector_id" {
  description = "ID of the Serverless VPC Access connector"
  value       = google_vpc_access_connector.connector.id
}
