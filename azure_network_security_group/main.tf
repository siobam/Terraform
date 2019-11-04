locals {
   inbound_network_security_rules =  [{
      name                        = "in_http"
      protocol                    = "TCP"
      destination_port_range      = 80
     },
     {      
       name                        = "in_http2"
       access                      = "Deny"
       protocol                    = "TCP"
       destination_port_range      = 8080
       source_address_prefix       = "10.10.10.10"
     }
   ]
   outbound_network_security_rules = [
    {
        name                        = "in_http"
        protocol                    = "TCP"
        destination_port_range      = 80
    }
   ]
 }

module "nsg" {
  source = "../module/NSG/nsg" # allow http and https 
  name                = "test-net-01"
  resource_group_name = "test"
  location            = "eastus"

  inbound_rules               = "${local.inbound_network_security_rules}"
  outbound_rules               = "${local.outbound_network_security_rules}"

  subnet_ids                  = ["/vnet/subnet/id1","/vnet/subnet/id1"]
}
