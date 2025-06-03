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
          dynamic "env" {
            for_each = containers.value["env"]
            content {
              name  = env.value["name"]
              value = env.value["value"]
            }            
          }
          image = containers.value["image"]
        }
      }
    }
  }
}
