output "id" {
  value = "${azurerm_virtual_network_gateway.gateway.id}"
}
output "cfg_id" {
  value = "${sha1(format(null_resource.gateway_cert_for_webapp.id))}"
}
output "name" {
  value = "${var.name}"
}

output "ip" {
  value = "${azurerm_public_ip.gateway.ip_address}"
}
output "vpn" {
  value = "${lookup(data.external.vpn_client_package.result,"vpn")}"
}
