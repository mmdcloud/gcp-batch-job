variable "name"{}
variable "location"{}
variable "deletion_protection"{}
variable "sa" {}
variable "containers" {
    type = list(object({
        image  = string
    }))
}