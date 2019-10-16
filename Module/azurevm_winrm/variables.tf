variable "location" {}
variable "resource_group_name" {}
variable "subnet_id" {}
variable "private_ip_address" {}
variable "dns_servers" {
  type = "list"
}
variable "vm_name" {}
variable "vm_size" {}
variable "disk_type" {}
variable "admin_username" {}
variable "admin_password" {}

variable "availability_set_id" {}
variable "load_balancer_backend_address_pools_ids" {}
variable "disk_size_gb" {}


variable "image_publisher" {
    default = "MicrosoftWindowsServer"
}
variable "image_offer" {
     default = "WindowsServer"
}
variable "image_sku" {
    default = "2016-Datacenter"
}
variable "image_version" {
    default = "latest"
}
variable "octopus_connection_string" {
}
