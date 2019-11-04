provider "azurerm" {
  subscription_id = "${var.provider_default["subscription_id"]}"
  client_id       = "${var.provider_default["client_id"]}"
  client_secret   = "${var.provider_default["client_secret"]}"
  tenant_id       = "${var.provider_default["tenant_id"]}"
  version         = "=1.35.0"
}
terraform {
  backend "azurerm" {}
}
module "database" {
  source = "../../modules/azure_dashboard"
    AADSecret = "${var.provider_default["client_secret"]}"
    resource_group_name = "${var.provider_default["resource_group_name"]}"
    resource_type = "database"
    element_height = 3
    element_weight = 5
    name = "${var.provider_default["resource_group_name"]}-database_DTU"
    location       = "${var.provider_default["location"]}"
}
 
module "app_service" {
  source = "../../modules/azure_dashboard"
    AADSecret = "${var.provider_default["client_secret"]}"
    resource_group_name = "${var.provider_default["resource_group_name"]}"
    resource_type = "app_service"
    element_height = 3
    element_weight = 5
    name = "${var.provider_default["resource_group_name"]}-application_user_experiance"
    location       = "${var.provider_default["location"]}"
}

module "app_service_plan" {
  source = "../../modules/azure_dashboard"
    AADSecret = "${var.provider_default["client_secret"]}"
    resource_group_name = "${var.provider_default["resource_group_name"]}"
    resource_type = "app_service_plan"
    element_height = 3
    element_weight = 5
    name = "${var.provider_default["resource_group_name"]}-app_service_plan"
    location       = "${var.provider_default["location"]}"
}

module "virtual_machine" {
  source = "../../modules/azure_dashboard"
    AADSecret = "${var.provider_default["client_secret"]}"
    resource_group_name = "${var.provider_default["resource_group_name"]}"
    resource_type = "virtual_machine"
    element_height = 3
    element_weight = 5
    name = "${var.provider_default["resource_group_name"]}-virtual_machine"
    location       = "${var.provider_default["location"]}"
}