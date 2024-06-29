
provider "google" {
  project     = var.project_id
  region      = "asia-northeast1"
}


# GKE Autopilot Cluster
resource "google_container_cluster" "plat_dev" {
  name               = "plat-dev"
  location           = "asia-northeast1"
  enable_autopilot   = true
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
