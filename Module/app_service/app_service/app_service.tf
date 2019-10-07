
data "azurerm_client_config" "current" {}
resource "null_resource" "depends_on_gateway" {
  triggers {
    configuration_id = "${var.depends_on}"
  }
}

resource "azurerm_app_service" "app_service" {
  depends_on = ["null_resource.depends_on_gateway"]
  name                    = "${var.name}"
  location                = "${var.location}"
  resource_group_name     = "${var.resource_group_name}"
  app_service_plan_id     = "${var.app_service_plan_id}"
  https_only              = true
  client_affinity_enabled = false

  site_config {
    always_on                 = true
    use_32_bit_worker_process = false
    min_tls_version           = "${var.tls_version}"
    virtual_network_name      = "${var.virtual_network_name}"
    dotnet_framework_version  = "${var.dotnet_framework_version}" #The version of the .net framework's CLR used in this App Service. Possible values are v2.0 (which will use the latest version of the .net framework for the .net CLR v2 - currently .net 3.5) and v4.0 (which corresponds to the latest version of the .net CLR v4 - which at the time of writing is .net 4.7.1). For more information on which .net CLR version to use based on the .net framework you're targeting - please see this table. Defaults to v4.0. 
    ftps_state                = "Disabled"
    remote_debugging_enabled  = false
    ip_restriction            = ["${var.ip_restriction}"]
  }
  app_settings {
    INACTIVE_DEPLOYMENT_SLOT = "false"
  }
  lifecycle {
        ignore_changes = [
            "site_config.0.scm_type",
            "app_settings"
        ]
  }
}
locals {
  slotName = "deploymentslot"
  script_path = "${path.module}/scripts"
}

resource "azurerm_app_service_slot" "azurerm_app_service_slot" {
  name                = "${local.slotName}"
  app_service_name    = "${azurerm_app_service.app_service.name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  app_service_plan_id = "${var.app_service_plan_id}"
  https_only              = true
  client_affinity_enabled = false
  site_config {
    always_on                 = true
    use_32_bit_worker_process = false
    min_tls_version           = "${var.tls_version}"
    virtual_network_name      = "${var.virtual_network_name}"
    dotnet_framework_version  = "v4.0"                        #The version of the .net framework's CLR used in this App Service. Possible values are v2.0 (which will use the latest version of the .net framework for the .net CLR v2 - currently .net 3.5) and v4.0 (which corresponds to the latest version of the .net CLR v4 - which at the time of writing is .net 4.7.1). For more information on which .net CLR version to use based on the .net framework you're targeting - please see this table. Defaults to v4.0. 
    ftps_state                = "Disabled"
    remote_debugging_enabled  = false
    ip_restriction            = ["${var.ip_restriction}"]
  }
  app_settings {
    INACTIVE_DEPLOYMENT_SLOT = "true"
  }
  lifecycle {
        ignore_changes = [
            "site_config.0.scm_type",
            "app_settings"
        ]
  }

}
# create application insight
resource "azurerm_application_insights" "application_insights" {
  count               = "${var.application_insights}"
  name                = "${var.name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  application_type    = "WEB"
}

# integrate web app tp virtual network.
resource "null_resource" "New-AppServiceVnetIntegration" {
  depends_on = [
    "azurerm_app_service.app_service",
    "null_resource.depends_on_gateway"
  ]
  triggers {
    id                               = "${azurerm_app_service.app_service.id}"
    script_sha1                      = "${sha1(file("${local.script_path}/New-AppServiceVnetIntegration.ps1"))}"
    network_gateway_configuration_id = "${var.depends_on}"
  }
  provisioner "local-exec" {
    command = <<EOF
          powershell -file ${local.script_path}\New-AppServiceVnetIntegration.ps1 -VnetName "${var.virtual_network_name}" `
                                                                                  -WebApp "${var.name}" `
                                                                                  -ResourceGroup "${var.resource_group_name}" `
                                                                                  -Location "${var.location}" `
                                                                                  -AADSecret "${var.AADSecret}" `
                                                                                  -AADClientID "${data.azurerm_client_config.current.client_id}" `
                                                                                  -TenantID "${data.azurerm_client_config.current.tenant_id}" `
                                                                                  -SubscriptionId "${data.azurerm_client_config.current.subscription_id}" `
                                                                                  -AzureVPNClientPacakgeUrl "${var.vpn_client_package}"
    EOF
    interpreter = ["PowerShell", "-Command"]
  }
}
# create app service binding and ssl binding 
resource "null_resource" "New-AppServiceSSLBinding" {
  count = "${var.CNAME == "default_null" ? 0 : 1}"
  depends_on = ["azurerm_app_service.app_service"]
  triggers {
    hostname = "${var.CNAME}"
    thumbprint = "${var.Thumbprint}"
    Domain = "${var.Domain}"
    script = "${sha1(file("${local.script_path}/New-AppServiceSSLBinding.ps1"))}"
  }
  provisioner "local-exec" {
    command = <<EOF
           powershell -file ${local.script_path}\New-New-AppServiceSSLBinding.ps1 -CNAME "${var.CNAME}" `
                                                                                  -Domain "${var.Domain}" `
                                                                                  -GoDaddyAPIKey "${var.GoDaddyKey}" `
                                                                                  -GoDaddyAPISecret "${var.GoDaddySecret}" `
                                                                                  -AADSecret "${var.AADSecret}" `
                                                                                  -AADClientID "${data.azurerm_client_config.current.client_id}" `
                                                                                  -TenantID "${data.azurerm_client_config.current.tenant_id}" `
                                                                                  -WebAppName "${var.name}" `
                                                                                  -ResourceGroup "${var.resource_group_name}" `
                                                                                  -Thumbprint "${var.Thumbprint}" `
                                                                                  -SubscriptionID "${data.azurerm_client_config.current.subscription_id}"
    EOF
    interpreter = ["PowerShell", "-Command"]
  }
}
# add sticky settings to app service and slot 
resource "null_resource" "New-AppServiceStickySettings" {
  depends_on = ["azurerm_app_service.app_service"]
  triggers {
    webapp   = "${azurerm_app_service.app_service.id}"
    slot     = "${azurerm_app_service_slot.azurerm_app_service_slot.id}"
    script   = "${sha1(file("${path.module}/scripts/New-AppServiceStickySettings.ps1"))}"
  }
  provisioner "local-exec" {
    command = <<EOF
      powershell -file ${path.module}\scripts\New-AppServiceStickySettings.ps1 -ResourceGroup "${var.resource_group_name}" `
                                                                               -Location "${var.location}" `
                                                                               -WebApp "${var.name}" `
                                                                               -WebAppSlot "${local.slotName}" `
                                                                               -AADSecret "${var.AADSecret}" `
                                                                               -AADClientID "${data.azurerm_client_config.current.client_id}" `
                                                                               -TenantID "${data.azurerm_client_config.current.tenant_id}" `
                                                                               -SubscriptionId "${data.azurerm_client_config.current.subscription_id}"
    EOF
    interpreter = ["PowerShell", "-Command"]
  }
}

