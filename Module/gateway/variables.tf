variable "name" {}
variable "location" {}
variable "resource_group_name" {}
variable "vpn_address_space" {}
variable "enable_bgp" {
    default = "false"
}

variable "AADSecret" {}
variable "vnet_name" {}
variable "subnet_id" {}
variable "bgp_asn" {}
variable "bgp_peering_address" {}
