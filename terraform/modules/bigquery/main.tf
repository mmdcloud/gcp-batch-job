resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_id
}

resource "google_bigquery_table" "table" {
  count               = length(var.tables)
  dataset_id          = google_bigquery_dataset.dataset.dataset_id
  table_id            = var.tables[count.index].table
  schema              = var.tables[count.index].schema
  deletion_protection = var.tables[count.index].deletion_protection
}
