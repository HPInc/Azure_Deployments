/*
 * Copyright (c) 2020 Teradici Corporation
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
  address_prefixes     = ["10.${count.index}.3.0/24"]
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.azurerm_virtual_network_names[count.index]
}

resource "azurerm_subnet_network_security_group_association" "cac" {
  count = length(var.locations)

  subnet_id                 = azurerm_subnet.cac[count.index].id
  network_security_group_id = var.network_security_group_ids[count.index]
}

# One public ip per cac
resource "azurerm_public_ip" "cac" {
  count = length(var.cac_configuration)

  name                    = "public-ip-cac-${count.index}"
  location                = var.cac_configuration[count.index].location
  resource_group_name     = var.resource_group_name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  sku                     = "Standard"
}

# One network interface per cac
resource "azurerm_network_interface" "cac_nic" {
  count = length(var.cac_configuration)

  name                = "${local.prefix}cac-nic-${count.index}"
  location            = var.cac_configuration[count.index].location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "primary"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.cac[count.index].id
    subnet_id                     = azurerm_subnet.cac[index(var.locations, var.cac_configuration[count.index].location)].id
    primary                       = "true"
  }
}
