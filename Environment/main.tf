data "azurerm_virtual_network" "target" {
  name                = "tf1-vnet-01"
  resource_group_name = "tf1"
}
data "azurerm_virtual_network" "remote" {
  name                = "tf2-net-01"
  resource_group_name = "tf2"
  provider = "azurerm.remote"
}


module "vnet_peering_to_domain_network" {
  source = "..\\module\\cross_tenant_peering"
  cross_tenant_client_id  = "xxxxxxxxxx-xxxxxx-xxxxxx-xxxxxx-xxxxxxx"
  cross_tenant_client_secret = "werwerwffwefwefwefwefwefwefwef="
  target_tenant  = "eeeeeeee-eeeee-eeee-eeee-eeeeeeeeeeee"
  target_network_id  = "/subscriptions/eeeeeee-rrrr-rrrr-rrr-rrrr/resourceGroups/tf1/providers/Microsoft.Network/virtualNetworks/tf1-vnet-01"
  remote_tenant  = "wwwwwwww-wwwww-wwww-wwww-wwwwwwwwwww" 
  remote_network_id  = "/subscriptions/wwwwwwwww-wwwwww-wwww-wwwww-wwwwwwww/resourceGroups/tf2/providers/Microsoft.Network/virtualNetworks/tf2-net-01"
  target_network_peerings = "${data.azurerm_virtual_network.tf1.vnet_peerings}"
  remote_network_peerings = "${data.azurerm_virtual_network.tf2.vnet_peerings}"

  remote_peering_name = "tf1-net-01-and-tf2-vnet-01"
  target_peering_name = "tf2-vnet-01-and-tf1-net-01"
}