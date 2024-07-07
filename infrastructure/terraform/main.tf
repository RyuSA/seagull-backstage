
provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_project" "project" {}

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

resource "google_project_iam_member" "backstage_container_viewer" {
  project = var.project_id
  role    = "roles/container.viewer"
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

# Artifact Registry: asia-docker.pkg.dev/PROJECT_ID/backstage
resource "google_artifact_registry_repository" "backstage" {
  project       = var.project_id
  repository_id = "backstage"
  location      = var.region
  format        = "DOCKER"
}

# Reserved Public IP address "backstage"(Global)
resource "google_compute_global_address" "backstage" {
  name = "backstage"
}

resource "google_project_iam_member" "backstage_editor_workload_identity" {
  project = var.project_id
  role    = "roles/editor"
  member  = "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/default/sa/backstage"
}

resource "google_project_iam_member" "backstage_container_viewer_workload_identity" {
  project = var.project_id
  role    = "roles/container.clusterViewer"
  member  = "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/default/sa/my-sa"
}

resource "google_service_account_iam_member" "backstage_workload_identity" {
  service_account_id = google_service_account.backstage.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/backstage]"
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.plat_dev.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.plat_dev.master_auth.0.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

data "google_client_config" "default" {}

resource "kubernetes_service_account" "backstage" {
  metadata {
    name      = "backstage"
    namespace = "default"
    annotations = {
      "iam.gke.io/gcp-service-account" = "${google_service_account.backstage.email}"
    }
  }
}
