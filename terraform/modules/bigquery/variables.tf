variable "dataset_id" {}
variable "tables" {
  type = list(object({
    table = string
    schema = string
    deletion_protection = string
  }))
}