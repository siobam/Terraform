resource "azurerm_network_interface" "nic-01" {
  name                = "${var.vm_name}-nic-01"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  dns_servers         = "${var.dns_servers}"
  ip_configuration {
    name                                    = "${var.vm_name}-config"
    subnet_id                               = "${var.subnet_id}"
    private_ip_address                      = "${var.private_ip_address}"
    private_ip_address_allocation           = "static"
    load_balancer_backend_address_pools_ids = ["${var.load_balancer_backend_address_pools_ids}"]
  }
}
resource "azurerm_virtual_machine" "vm" {

  name                  = "${var.vm_name}"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${azurerm_network_interface.nic-01.id}"]
  vm_size               = "${var.vm_size}"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true
  availability_set_id              = "${var.availability_set_id}"

  storage_image_reference {
      publisher = "${var.image_publisher}"
      offer     = "${var.image_offer}"
      sku       = "${var.image_sku}"
      version = "${var.image_version}"
  }
  # e - (Optional) Specifies the type of managed disk to create. Value you must be either Standard_LRS or Premium_LRS.
  storage_os_disk {
    name              = "${var.vm_name}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${var.disk_type}"
  }
  os_profile_windows_config {
    provision_vm_agent = true
    enable_automatic_upgrades = true
    winrm = {
      protocol = "http"
    }
    # Auto-Login's required to configure WinRM
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${var.admin_password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.admin_username}</Username></AutoLogon>"
    }

    # Unattend config is to enable basic auth in WinRM, required for the provisioner stage.
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = "${file("${path.module}/FirstLogonCommands.xml")}"
    }
  }
  os_profile {
    computer_name  = "${var.vm_name}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
    custom_data    = "${file("${path.module}/winrm.ps1")}"
  }
  tags {
    environment = "${var.resource_group_name}-${var.location}"
    kind        = "consul"
  }
}

module "OctopusAgent" {
  source = "..\\..\\..\\module\\software\\OctopusAgent"
  depends_on = "${azurerm_virtual_machine.vm.id}" 

  host = "${var.private_ip_address}"
  user = "${var.admin_username}"
  password = "${var.admin_password}"
  OctopusConnectionString = "${var.octopus_connection_string}"
}





