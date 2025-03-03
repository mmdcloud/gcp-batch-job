resource "google_cloud_run_v2_job" "job" {
  name                = var.name
  location            = var.location
  deletion_protection = var.deletion_protection

  template {
    template {
      service_account = var.sa
      dynamic "containers" {
        for_each = var.containers
        content {
          image = containers.value["image"]
        }
      }
    }
  }
}
