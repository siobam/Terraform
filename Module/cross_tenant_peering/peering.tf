# Step 1. The service principal need to be able to get access to tenants.
# cross_tenant_client_id belong to primary tenant, skip if peering should be created within the same tenant
resource "azurerm_azuread_service_principal" "service_principal" {
  count          = "${var.target_tenant == var.remote_tenant ? 0:1}"
  application_id = "${var.cross_tenant_client_id}"
}
# to set role on network we need to get object id, it is not working with application id of service principal.
data "azurerm_azuread_service_principal" "service_principal" {
  count          = "${var.target_tenant == var.remote_tenant ? 1:0}"
  application_id = "${var.cross_tenant_client_id}"
}

locals {
  multitenant_service_principal_object_id = "${element(concat(azurerm_azuread_service_principal.service_principal.*.id, list("")),0)}"
  single_tenant_service_principal_object_id = "${element(concat(data.azurerm_azuread_service_principal.service_principal.*.object_id, list("")),0)}"
}

# Step 2. Assign Network Contributor role to manage remote network.
resource "azurerm_role_assignment" "role_assignment" {
 # depends_on = ["null_resource.depends_on"]
  scope                = "${var.target_network_id}"
  role_definition_name = "Network Contributor"
  principal_id         = "${local.multitenant_service_principal_object_id}${local.single_tenant_service_principal_object_id}"
}

# Step 3. Detect if user peering id already exist in network peering list.
# Note: if another peering with the same ID exist, terraform will throw an error because of unexpected behaviour
locals {
  target_peering = "${lookup(var.target_network_peerings, "${var.target_peering_name}", 0) == var.remote_network_id ? 1:0}"
  remote_peering = "${lookup(var.remote_network_peerings, "${var.remote_peering_name}", 0) == var.target_network_id ? 1:0}"
}


# Step 4. Create cross tenant peering
data "template_file" "script" { 
  template = "${file("${path.module}\\New-AzureCrossTenantNetworkPeering.ps1")}"
}
resource "null_resource" "create_cross_tenant_peering" {
  triggers {
    # trigger resource in case if some of settings below was cahnged
    target_tenant = " ${var.target_tenant}"
    target_network_id = "${var.target_network_id}"
    remote_tenant = "${var.remote_tenant}"
    remote_network_id = "${var.remote_network_id}"
    script = "${data.template_file.script.rendered}"        # detect changes in script
    remote_peering_name = "${var.remote_peering_name} "
    target_peering_name = "${var.target_peering_name}"
    target_peering = "${local.target_peering}"          
    remote_peering =  "${local.remote_peering}"
  }
  depends_on = ["azurerm_role_assignment.role_assignment"]
  provisioner "local-exec" {
    command = <<EOF
      $TargetNetworkPeering = '${jsonencode(var.target_network_peerings)}' -replace '"',''''
      $RemoteNetworkPeering = '${jsonencode(var.remote_network_peerings)}' -replace '"',''''
      powershell -file ${path.module}\New-AzureCrossTenantNetworkPeering.ps1 -CrossTenantAADClientId "${var.cross_tenant_client_id}" `
                                                                             -CrossTenantAADClientSecret "${var.cross_tenant_client_secret}" `
                                                                             -TargetTenant "${var.target_tenant}" `
                                                                             -TargetNetworkId "${var.target_network_id}" `
                                                                             -RemoteTenant "${var.remote_tenant}" `
                                                                             -RemoteNetworkId "${var.remote_network_id}" `
                                                                             -RemotePeeringName "${var.remote_peering_name}" `
                                                                             -TargetPpeeringName "${var.target_peering_name}" `
                                                                             -TargetNetworkPeering $TargetNetworkPeering `
                                                                             -RemoteNetworkPeering $RemoteNetworkPeering

EOF
    interpreter = ["PowerShell", "-Command"]
  }
}
