output "name" {
  value = "${azurerm_app_service.app_service.name}"
}

output "instrumentation_key" {
  value = "${azurerm_application_insights.application_insights.*.instrumentation_key}"
}

output "app_id" {
  value = "${azurerm_application_insights.application_insights.*.app_id}"
}

output "alias" {
  value = "${azurerm_app_service.app_service.default_site_hostname}"
}
