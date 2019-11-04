
variable "sku" {
  type = "map"
  default = {
      tier = "PremiumV2"
      size = "P2v2"
      capacity = "1"
  }
}

module "virtual_network01" {
  source = "../module/vnet"
  name                = "tf-net-01"
  location = "eastus"
  resource_group_name =  "tf"
  address_space= "10.1.0.0/16"
  dns_servers = ["8.8.8.8"]
}

module "virtual_network01_GatewaySubnet" {
  source = "../module/subnet"

  name                      = "GatewaySubnet"
  virtual_network_name      = "${module.virtual_network01.name}"
  resource_group_name       = "tf"
  address_prefix            = "10.1.1.0/24"
  network_security_group_id = ""
}
module "virtual_network01_gateway" {
  source = "../module/gateway"

  name                     = "tf-gw-01"
  location                 = "eastus"
  resource_group_name      = "tf"
  vpn_address_space        = "172.16.0.0/24"
  vnet_name                = "${module.virtual_network01.name}"
  subnet_id                = "${module.virtual_network01_GatewaySubnet.id}"
  AADSecret                = "qweqweqweqweqweqweqweqweqweqweqwewqw="               # app id client secret  for Connect-AzureRmAccount

  # user certificates thumprint for PPTP (VPN)
  enable_bgp                        = "true"
  bgp_asn                           = "65020"
  bgp_peering_address               = "10.1.1.254"
}
locals {
    app_service_ip_restriction = [
        {
          ip_address = "${element(split("/","10.0.0.0/24"),0)}",
          subnet_mask = "${cidrnetmask("10.0.0.0/24")}"
        },
        {
          ip_address = "${element(split("/","10.0.0.1/24"),0)}",
          subnet_mask = "${cidrnetmask("10.0.0.1/24")}"
        },
        {
          virtual_network_subnet_id = "${module.virtual_network01.id}"
        }
  ]
}
module "app_service_plan01" {
  source = "../module/app_service/app_service_plan"

  name                = "tf-appplan-01"
  resource_group_name = "tf"
  location            = "eastus"
  sku                = "${var.sku}"
  depend_on_keyvault             = "in case if you import SSL certificate from key vault"
  depend_on_keyvault_certificate = "in case if you import SSL certificate from key vault"
}
module "devtoolkit" {
  source = "../module/app_service/app_service"

  name                 = "tf-web-ui"
  resource_group_name  = "tf"
  location             = "eastus"
  app_service_plan_id  = "${module.app_service_plan01.id}"
  virtual_network_name = "${module.virtual_network01.name}"
  gateway_name         = "${module.virtual_network01_gateway.name}"
  AADSecret            = "wwwwwwwwwwwwwwwwwwww="
  vpn_client_package   = "${module.virtual_network01_gateway.vpn}"
  ip_restriction       = "${local.app_service_ip_restriction}"

  depends_on = "${module.virtual_network01_gateway.cfg_id}"
}