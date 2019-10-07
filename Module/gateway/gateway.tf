data "azurerm_client_config" "current" {}

resource "azurerm_public_ip" "gateway" {
  name                = "${var.name}-pip-01"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  public_ip_address_allocation = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "gateway" {
  name                = "${var.name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = "${var.enable_bgp}"
  sku           = "Standard"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = "${azurerm_public_ip.gateway.id}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${var.subnet_id}"
  }
  bgp_settings  {
    asn = "${var.bgp_asn}"
    peering_address = "${var.bgp_peering_address}"
  }
  vpn_client_configuration {
    address_space        = ["${var.vpn_address_space}"]
    vpn_client_protocols = ["SSTP"]
  }
  lifecycle {
      ignore_changes = [
            "vpn_client_configuration.0.root_certificate"
      ]
   }
}
# get gateway.
data "azurerm_virtual_network_gateway" "gw" {
  name                = "${azurerm_virtual_network_gateway.gateway.name}"
  resource_group_name = "${var.resource_group_name}"
}


resource "null_resource" "gateway_cert_for_webapp" {
  triggers {
    id                       = "${azurerm_virtual_network_gateway.gateway.id}"
    gateway_certificate = "${jsonencode(data.azurerm_virtual_network_gateway.gw.vpn_client_configuration.0.root_certificate)}"
    script = "${sha1(file("${path.module}/Update-AppServiceGatewayCertificate.ps1"))}"
  }

  provisioner "local-exec" {
    command = <<EOF
          powershell -file ${path.module}\Update-AppServiceGatewayCertificate.ps1 -AADSecret "${var.AADSecret}" `
                                                                                  -AADClientID "${data.azurerm_client_config.current.client_id}" `
                                                                                  -TenantID "${data.azurerm_client_config.current.tenant_id}" `
                                                                                  -GatewayId  "${azurerm_virtual_network_gateway.gateway.id}"
    EOF
    interpreter = ["PowerShell", "-Command"]
  }
}
data "null_data_source" "certificate" {
  inputs = {
    trigger = "${format(null_resource.gateway_cert_for_webapp.id)}"
    gateway_name = "${azurerm_virtual_network_gateway.gateway.name}"
  }
}
data "azurerm_virtual_network_gateway" "certificate" {
  name                = "${data.null_data_source.certificate.outputs["gateway_name"]}"
  resource_group_name = "${var.resource_group_name}"
}
data "external" "vpn_client_package" {
#  depends_on = ["null_resource.gateway_cert_for_webapp"]
  program = ["PowerShell", "${path.module}/Get-AzureGatewayVpnClientUrl.ps1"]
  query = {
      GatewayName = "${data.null_data_source.certificate.outputs["gateway_name"]}",
      ResourceGroup = "${var.resource_group_name}",
      AADSecret = "${var.AADSecret}",
      AADClientID = "${data.azurerm_client_config.current.client_id}",
      TenantID = "${data.azurerm_client_config.current.tenant_id}",
      SubscriptionId = "${azurerm_virtual_network_gateway.gateway.id}"
  }
}
