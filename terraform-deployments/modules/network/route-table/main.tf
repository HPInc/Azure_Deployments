/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

resource "azurerm_route_table" "cac-rt" {
  name                = "cac-routetable"
  location            = var.locations[0]
  resource_group_name = var.resource_group_name

  route {
    name                   = "DefaultRouteOverride"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fw_private_ip
  }

  route {
    name                   = "Internet"
    address_prefix         = "${var.fw_public_ip}/32"
    next_hop_type          = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "cac-subnet" {
  subnet_id      = var.cac_subnet_ids[0]
  route_table_id = azurerm_route_table.cac-rt.id
}

resource "azurerm_subnet_route_table_association" "ws-subnet" {
  subnet_id      = var.ws_subnet_ids[0]
  route_table_id = azurerm_route_table.cac-rt.id
}