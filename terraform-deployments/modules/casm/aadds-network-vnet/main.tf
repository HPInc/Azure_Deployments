/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

resource "azurerm_network_security_group" "nsg" {

  count = 1

  name                = "${local.prefix}dc-nsg-${var.locations[count.index]}"
  location            = var.locations[count.index]
  resource_group_name = var.resource_group_name
}

resource "azurerm_virtual_network" "main_vnet" {
	name                = var.main_vnet_name
	address_space       = [var.vnet_cidr]
	location            = var.locations[0]
	resource_group_name = var.resource_group_name
  dns_servers         = data.azurerm_virtual_network.aadds_vnet.dns_servers
}

data "azurerm_virtual_network" "aadds_vnet" {
  name                 = var.aadds_vnet_name
  resource_group_name  = var.aadds_vnet_rg
}

resource "azurerm_virtual_network_peering" "aadds_peering" {
  name                      = "peer_aadds"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.main_vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.aadds_vnet.id
}

resource "azurerm_virtual_network_peering" "aadds_peering_2" {
  name                      = "peer_${var.resource_group_name}"
  resource_group_name       = var.aadds_vnet_rg
  virtual_network_name      = var.aadds_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.main_vnet.id
}

resource "azurerm_network_security_rule" "nsg_allow_all_vnet" {
  count = 1

  name                       = "allow-all-vnet-${local.network_security_rule_prefixes[count.index][0]}-${local.network_security_rule_prefixes[count.index][1]}"
  priority                   = count.index + 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "*"
  source_port_range          = "*"
  destination_port_ranges    = ["1-65525"]
  source_address_prefix      = "10.0.0.0/8"
  destination_address_prefix = "*"
  resource_group_name        = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[
    local.network_security_rule_prefixes[count.index][1]
  ].name
}

resource "azurerm_network_security_rule" "nsg_pcoip" {
  count = 1

  name                        = "allow-pcoip"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges     = ["443", "4172"]
  source_address_prefix       = var.allowed_client_cidrs
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[count.index].name
}

# WinRM port used to upload scripts
resource "azurerm_network_security_rule" "nsg_5985" {
  count = 1

  name                        = "winrm-port-5985"
  priority                    = 201
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5985"
  source_address_prefix       = chomp(data.http.myip.response_body)
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[count.index].name
}

# WinRM port used to upload scripts
resource "azurerm_network_security_rule" "nsg_5986" {
  count = 1

  name                        = "winrm-port-5986"
  priority                    = 202
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5986"
  source_address_prefix       = chomp(data.http.myip.response_body)
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[count.index].name
}


# SSH port used to upload scripts
resource "azurerm_network_security_rule" "nsg_22" {
  count = 1

  name                        = "ssh-port-22"
  priority                    = 203
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = chomp(data.http.myip.response_body)
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[count.index].name
}

# RDP port open for debugging only
resource "azurerm_network_security_rule" "nsg_3389" {
  # Only open rdp port if we are creating public ip addresses
  #count = var.create_debug_rdp_access == true ? length(azurerm_virtual_network.network) : 0
  count = 1
  
  name                        = "debug-rdp-port-3389"
  priority                    = 204
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = chomp(data.http.myip.response_body)
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[count.index].name
}

# One workstation subnet per region
resource "azurerm_subnet" "workstation" {
  depends_on = [azurerm_virtual_network.main_vnet]
  count = 1
  name                 = "${var.workstation_subnet_name}-${var.locations[0]}-${var.resource_group_name}"
  address_prefixes     = var.ws_subnet_cidr
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
}

# Nat per location
resource "azurerm_public_ip" "nat" {
  count = 1

  name                    = "public-nat-ip-${var.locations[count.index]}"
  location                = var.locations[count.index]
  resource_group_name     = var.resource_group_name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  sku                     = "Standard"
}

resource "azurerm_public_ip_prefix" "nat" {
  count = 1

  name                = "nat-gateway-PIPP-${var.locations[count.index]}"
  location            = var.locations[count.index]
  resource_group_name = var.resource_group_name
  prefix_length       = 30
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat" {
  count = 1

  name                    = "nat-gateway-${var.locations[count.index]}"
  location                = var.locations[count.index]
  resource_group_name     = var.resource_group_name
  idle_timeout_in_minutes = 10
  sku_name                = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  count = 1

  nat_gateway_id       = azurerm_nat_gateway.nat[count.index].id
  public_ip_address_id = azurerm_public_ip.nat[count.index].id
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "main" {
  count = 1

  nat_gateway_id = azurerm_nat_gateway.nat[count.index].id
  public_ip_prefix_id = azurerm_public_ip_prefix.nat[count.index].id
}

resource "azurerm_subnet_nat_gateway_association" "nat" {
  count = 1
  depends_on = [
    azurerm_nat_gateway.nat[0],
    azurerm_subnet.workstation[0]
  ]
  subnet_id      = azurerm_subnet.workstation[count.index].id
  nat_gateway_id = azurerm_nat_gateway.nat[count.index].id
}

resource "azurerm_subnet_network_security_group_association" "workstation" {
  count = 1
  depends_on = [
    azurerm_subnet.workstation[0]
  ]
  subnet_id                 = azurerm_subnet.workstation[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg[count.index].id
}
