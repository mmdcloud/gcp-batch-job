locals {
  artifact_type = "DOCKER"
}

# Service account for batch job
module "batch_job_sa" {
  source       = "./modules/iam"
  account_id   = "batch-job-sa"
  display_name = "batch-job-sa"
  permissions = [
    "roles/artifactregistry.admin",
    "roles/storage.admin",
    "roles/bigquery.admin",
    "roles/run.admin"
  ]
  project_id = var.project_id
}

# Artifact Registry
module "batch_job_artifact_registry" {
  source        = "./modules/artifact-registry"
  location      = var.location
  description   = "Batch Job Artifact Registry"
  repository_id = "batch-job-artifact-registry"
  shell_command = "bash ${path.cwd}/../artifact_push.sh batchnews ${var.location} ${var.project_id}"
}

module "batchnews_job" {
  source              = "./modules/cloud-run-job"
  name                = "batchnews"
  location            = var.location
  deletion_protection = false
  sa                  = module.batch_job_sa.email
  containers = [
    {
      image = "${var.location}-docker.pkg.dev/${var.project_id}/batchnews/batchnews:latest"
    }
  ]
  depends_on = [module.batch_job_artifact_registry]
}

# BigQuery configuration 
module "batch_job_bq" {
  source     = "./modules/bigquery"
  dataset_id = "batchnews"
  tables = [
    {
      table               = "batchnewstable"
      schema              = <<EOF
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
  ]
}
