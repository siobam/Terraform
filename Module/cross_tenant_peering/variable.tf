
variable "cross_tenant_client_secret" {
}
variable "cross_tenant_client_id" {
}
variable "target_tenant" {
}
variable "target_network_id" {
}
variable "remote_tenant" {
}
variable "remote_network_id" {
}

variable "remote_network_peerings" {
  type = "map"
}
variable "target_network_peerings" {
  type = "map"
}
variable "remote_peering_name" {
  
}
variable "target_peering_name" {
  
}
