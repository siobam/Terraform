variable "application_insights" {
  default = "0"
}

variable "location" {}
variable "name" {}
variable "resource_group_name" {}
variable "app_service_plan_id" {}
variable "AADSecret" {}
variable "depends_on" {
}

variable "CNAME" {
  default = "default_null"
}

variable "Thumbprint" {
  default = ""
}

variable "GoDaddyKey" {
  default = ""
}

variable "GoDaddySecret" {
  default = ""
}

variable "gateway_name" {
  default = "do_not_integrat"
}


variable "default_documents" {
  default = ""
}

variable "virtual_network_name" {
  default = ""
}


variable "Domain" {
  default = ""
}

variable "tls_version" {
  default = "1.2"
}

variable "dotnet_framework_version" {
  default = "V4.0"
}
variable "vpn_client_package" {
  
}
variable "ip_restriction" {
  type = "list"
}
