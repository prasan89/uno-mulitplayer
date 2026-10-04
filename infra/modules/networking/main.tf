# ============================================================
# Networking module
# Provisions: VPC, regional subnet, VPC connector (Cloud Run),
#             Cloud NAT (outbound internet), private service
#             networking peering (Cloud SQL private IP)
# ============================================================

# ---- VPC -------------------------------------------------------

resource "google_compute_network" "wilddeck_vpc" {
  project                 = var.project_id
  name                    = "wilddeck-vpc"
  auto_create_subnetworks = false
  description             = "VPC network for the WildDeck application"
}

# ---- Subnet ----------------------------------------------------

# Primary subnet used by Cloud Run, Cloud SQL, and Redis
resource "google_compute_subnetwork" "wilddeck_subnet" {
  project                  = var.project_id
  name                     = "wilddeck-subnet-${var.region}"
  region                   = var.region
  network                  = google_compute_network.wilddeck_vpc.id
  ip_cidr_range            = "10.0.0.0/24"
  private_ip_google_access = true # allows VMs to reach Google APIs without external IPs
}

# ---- VPC Connector (Cloud Run → VPC) ---------------------------

# Allows Cloud Run instances to reach private resources (Cloud SQL, Redis)
resource "google_vpc_access_connector" "connector" {
  provider = google-beta

  project        = var.project_id
  name           = "wilddeck-vpc-connector"
  region         = var.region
  network        = google_compute_network.wilddeck_vpc.name
  ip_cidr_range  = "10.8.0.0/28" # /28 is the minimum required by the connector
  min_throughput = 200
  max_throughput = 1000
}

# ---- Cloud Router + Cloud NAT ----------------------------------

# Router required by Cloud NAT
resource "google_compute_router" "wilddeck_router" {
  project = var.project_id
  name    = "wilddeck-router"
  region  = var.region
  network = google_compute_network.wilddeck_vpc.id
}

# Cloud NAT provides outbound internet access for instances without external IPs
resource "google_compute_router_nat" "wilddeck_nat" {
  project                            = var.project_id
  name                               = "wilddeck-nat"
  router                             = google_compute_router.wilddeck_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# ---- Private Service Networking (Cloud SQL private IP) ---------

# Reserve a global IP range that Google uses for VPC peering (Cloud SQL)
resource "google_compute_global_address" "private_ip_range" {
  project       = var.project_id
  name          = "wilddeck-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.wilddeck_vpc.id
}

# Establish the private service connection so Cloud SQL gets a private IP
resource "google_service_networking_connection" "private_service_connection" {
  network                 = google_compute_network.wilddeck_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}
