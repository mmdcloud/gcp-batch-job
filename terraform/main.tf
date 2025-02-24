locals {
  artifact_type = "DOCKER"

}
resource "google_service_account" "batchnews_service_account" {
  account_id   = "${var.repository_id}-sa"
  display_name = "${var.repository_id}-sa"
}

resource "google_project_iam_member" "artifact_registry_administrator" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_service_account.batchnews_service_account.email}"
}

resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.batchnews_service_account.email}"
}

resource "google_project_iam_member" "bigquery_admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.batchnews_service_account.email}"
}

resource "google_project_iam_member" "cloud_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.batchnews_service_account.email}"
}

resource "google_artifact_registry_repository" "batchnews_repo" {
  location      = var.location
  repository_id = var.repository_id
  description   = var.repository_description
  format        = local.artifact_type
}

resource "null_resource" "batchnews_artifact" {
  provisioner "local-exec" {
    command = "bash ${path.cwd}/../artifact_push.sh batchnews ${var.location} ${var.project_id}"
  }
}

resource "google_cloud_run_v2_job" "batchnews_job" {
  name                = "batchnews"
  location            = var.location
  deletion_protection = false
  
  template {    
    template {
      service_account = google_service_account.batchnews_service_account.email
      containers {
        image = "${var.location}-docker.pkg.dev/${var.project_id}/batchnews/batchnews:latest"
      }
    }
  }
  depends_on = [null_resource.batchnews_artifact]
}

resource "google_bigquery_dataset" "batchnews_dataset" {
  dataset_id = "batchnews"
}

resource "google_bigquery_table" "batchnews_table" {
  table_id   = "batchnewstable"
  dataset_id = google_bigquery_dataset.batchnews_dataset.dataset_id

  schema = <<EOF
[
  {
    "name": "title",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "title"
  },
  {
    "name": "description",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "description"
  },
  {
    "name": "url",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "url"
  }
]
EOF

  deletion_protection = false
}
