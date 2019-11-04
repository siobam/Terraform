resource "azurerm_network_security_group" "nsg" {
  name                = "${var.name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}
resource "azurerm_network_security_rule" "inbound_rules" {
  depends_on                  = ["azurerm_network_security_group.nsg"]
  count                       = "${length(var.inbound_rules)}"

  name                        = "${lookup(var.inbound_rules[count.index], "name")}"
  priority                    = "${lookup(var.inbound_rules[count.index], "priority", "${count.index == 0 ? 100:count.index +100}")}"
  direction                   = "${lookup(var.inbound_rules[count.index], "direction", "Inbound")}"
  access                      = "${lookup(var.inbound_rules[count.index], "access", "Allow")}"
  protocol                    = "${lookup(var.inbound_rules[count.index], "protocol")}"
  source_port_range           = "${lookup(var.inbound_rules[count.index], "source_port_range", "*")}"
  destination_port_range      = "${lookup(var.inbound_rules[count.index], "destination_port_range", "*")}"
  source_address_prefix       = "${lookup(var.inbound_rules[count.index], "source_address_prefix", "*")}"
  destination_address_prefix  = "${lookup(var.inbound_rules[count.index], "destination_address_prefix", "*")}"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${var.name}"
}
resource "azurerm_network_security_rule" "outbound_rules" {
  depends_on                  = ["azurerm_network_security_group.nsg"]
  count                       = "${length(var.outbound_rules)}"

  name                        = "${lookup(var.outbound_rules[count.index], "name")}"
  priority                    = "${lookup(var.outbound_rules[count.index], "priority", "${count.index == 0 ? 100:count.index +100}")}"
  direction                   = "${lookup(var.outbound_rules[count.index], "direction", "Oubound")}"
  access                      = "${lookup(var.outbound_rules[count.index], "access", "Allow")}"
  protocol                    = "${lookup(var.outbound_rules[count.index], "protocol")}"
  source_port_range           = "${lookup(var.outbound_rules[count.index], "source_port_range", "*")}"
  destination_port_range      = "${lookup(var.outbound_rules[count.index], "destination_port_range", "*")}"
  source_address_prefix       = "${lookup(var.outbound_rules[count.index], "source_address_prefix", "*")}"
  destination_address_prefix  = "${lookup(var.outbound_rules[count.index], "destination_address_prefix", "*")}"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${var.name}"
}

