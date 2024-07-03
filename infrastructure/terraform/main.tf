
provider "google" {
  project = var.project_id
  region  = var.region
}

# GKE Autopilot Cluster
resource "google_container_cluster" "plat_dev" {
  name             = "plat-dev"
  location         = var.region
  enable_autopilot = true
}

# Service Account for the applications
resource "google_service_account" "backstage" {
  account_id   = "backstage"
  display_name = "Backstage Service Account"
}

data "google_iam_policy" "gcs_read_policy" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "serviceAccount:${google_service_account.backstage.email}",
    ]
  }
}

resource "google_project_iam_member" "backstage_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.backstage.email}"
}

data "google_compute_network" "default" {
  name = "default"
}

resource "google_project_service" "service_networking" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"
}

resource "google_compute_global_address" "private_ip_address" {
  project       = var.project_id
  name          = "cloudsql"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = data.google_compute_network.default.id
}

resource "google_service_networking_connection" "default" {
  network                 = data.google_compute_network.default.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "postgres_instance" {
  name             = "backstage"
  database_version = "POSTGRES_13"
  region           = var.region

  settings {
    tier = "db-f1-micro"

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = data.google_compute_network.default.id
    }
  }
}

resource "google_sql_user" "backstage_user" {
  name     = "backstage"
  instance = google_sql_database_instance.postgres_instance.name
  password = var.auth_proxy_password
}
