output "name" {
  value = "${azurerm_app_service_plan.app_service_plan.name}"
}

output "id" {
  value = "${azurerm_app_service_plan.app_service_plan.id}"
}

output "ip_restriction_id" {
  value = "${var.sku["tier"]}:${var.sku["size"]}:${var.sku["capacity"]}:${azurerm_app_service_plan.app_service_plan.id}"
}

output "possible_ips" {
  value = ["${azurerm_app_service.possible_outbound_ip.possible_outbound_ip_addresses}"]
}
