resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "${var.name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  sku {
    tier = "${var.sku["tier"]}"
    size = "${var.sku["size"]}"
    capacity = "${var.sku["capacity"]}"
  }

  tags {
    depend_on_keyvault             = "${var.depend_on_keyvault}"
    depend_on_keyvault_certificate = "${var.depend_on_keyvault_certificate}"
  }
}


resource "azurerm_app_service" "possible_outbound_ip" {
  name                    = "${var.name}"
  location                = "${var.location}"
  resource_group_name     = "${var.resource_group_name}"
  app_service_plan_id     = "${azurerm_app_service_plan.app_service_plan.id}"
  https_only              = true
  client_affinity_enabled = false
}

