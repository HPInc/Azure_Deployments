/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

# One virtual network per location
resource "azurerm_virtual_network" "network" {
  depends_on = [var.dc_cac_network_depends_on]

  count = length(var.locations)

  name                = "${var.vnet_name}-${var.locations[count.index]}"
  location            = var.locations[count.index]
  address_space       = ["10.${count.index + 1}.0.0/16"]
  resource_group_name = var.resource_group_name
  dns_servers         = [var.dc_private_ip, "168.63.129.16"]
}

resource "azurerm_network_security_group" "nsg" {

  count = length(azurerm_virtual_network.network)

  name                = "${local.prefix}dc-nsg-${var.locations[count.index]}"
  location            = var.locations[count.index]
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_security_rule" "nsg_allow_all_vnet" {
  count = length(local.network_security_rule_prefixes)

  name                       = "allow-all-vnet-${local.network_security_rule_prefixes[count.index][0]}-${local.network_security_rule_prefixes[count.index][1]}"
  priority                   = count.index + 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "*"
  source_port_range          = "*"
  destination_port_ranges    = ["1-65525"]
  source_address_prefix      = "10.${local.network_security_rule_prefixes[count.index][0]}.0.0/16"
  destination_address_prefix = "*"
  resource_group_name        = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[
    local.network_security_rule_prefixes[count.index][1]
  ].name
}

resource "azurerm_network_security_rule" "nsg_pcoip" {
  count = length(azurerm_virtual_network.network)

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
  count = length(azurerm_virtual_network.network)

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
  count = length(azurerm_virtual_network.network)

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
  count = length(azurerm_virtual_network.network)

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
  count = var.create_debug_rdp_access == true ? length(azurerm_virtual_network.network) : 0

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
  count = length(var.locations)

  name                 = "${var.workstation_subnet_name}-${var.locations[count.index]}"
  address_prefixes     = ["10.${count.index + 1}.${count.index + 4}.0/24"]
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.network[count.index].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "cac" {
  count = length(azurerm_virtual_network.network)

  name                  = "dns-vnet-link-${var.locations[count.index]}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = var.dns-name
  virtual_network_id    = azurerm_virtual_network.network[count.index].id
}

resource "azurerm_subnet_network_security_group_association" "workstation" {
  count = length(var.locations)

  subnet_id                 = azurerm_subnet.workstation[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg[count.index].id
}

# If valid create virtual network peer to peer links
resource "azurerm_virtual_network_peering" "peering_to_satellite_locations" {
  count = length(var.vnet_peer_to_peer_links)

  name                         = "peering-to-sattelite-${count.index}"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = var.main_vnet_name
  remote_virtual_network_id    = azurerm_virtual_network.network[count.index].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "peering_to_main_location" {
  count = length(var.vnet_peer_to_peer_links)

  name                         = "peering-to-${count.index}"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.network[count.index].name
  remote_virtual_network_id    = var.main_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}
