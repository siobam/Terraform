variable "name" {}
variable "location" {}

variable "resource_group_name" {}

variable "sku" {
  type = "map"
}

variable "depend_on_keyvault" {}
variable "depend_on_keyvault_certificate" {}
