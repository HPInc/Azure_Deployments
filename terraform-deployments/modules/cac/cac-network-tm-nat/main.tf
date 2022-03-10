/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  prefix = var.prefix != "" ? "${var.prefix}-" : ""
}

# One cac subnet network per location
resource "azurerm_subnet" "cac" {
  depends_on = [var.cac_network_depends_on]

  count = length(var.locations)

  name                 = "${var.cac_subnet_name}-${var.locations[count.index]}"
  address_prefixes     = ["10.${var.vnet_num}.3.0/24"]
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.azurerm_virtual_network_names[0]
}

resource "azurerm_subnet_network_security_group_association" "cac" {
  count = length(var.locations)

  subnet_id                 = azurerm_subnet.cac[0].id
  network_security_group_id = var.network_security_group_ids[0]
}

# One network interface per cac
resource "azurerm_network_interface" "cac_nic" {
  count = length(var.cac_configuration)

  name                = "${local.prefix}cac-${var.locations[0]}-${count.index}"
  location            = var.locations[0]
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "primary"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.cac[0].id
    primary                       = "true"
  }
}
