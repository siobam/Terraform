output "name" {
  value = "${azurerm_virtual_machine.vm.name}"
}

output "login" {
  value = "${var.admin_username}"
}

output "password" {
  value = "${var.admin_password}"
}
