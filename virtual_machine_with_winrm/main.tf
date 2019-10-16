
module "windows_vm_with_winrm" {
  source = "../module/virtual_machine_with_winrm"
  location        = ""
  resource_group_name  = ""
  subnet_id           = ""
  private_ip_address  = ""
  dns_servers         = ""
  vm_name             = ""
  vm_size             = ""
  disk_type           = ""
  admin_username      = ""
  admin_password      = ""
  availability_set_id = ""
  load_balancer_backend_address_pools_ids = ""
  disk_size_gb        = ""

  octopus_connection_string = "url=https://octo.com;key=API-KEIWH;THUMBPRINT=1234UFcertTHUMBPRINT;environment=DEV;role=services"
}

