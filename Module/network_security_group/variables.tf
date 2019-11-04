variable "inbound_rules" {
  type = "list"
  default = []
}
variable "outbound_rules" {
  type = "list"
  default = []
}

variable "resource_group_name" {}
variable "name" {}
variable "location" {}
