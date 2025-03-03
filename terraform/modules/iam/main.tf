resource "google_service_account" "service_account" {
  account_id   = var.account_id
  display_name = var.display_name
}

resource "google_project_iam_member" "permissions" {
  project = var.project_id
  count   = length(var.permissions)
  role    = var.permissions[count.index]
  member  = "serviceAccount:${google_service_account.service_account.email}"
}
