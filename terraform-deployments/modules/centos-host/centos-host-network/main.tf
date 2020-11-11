/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

 # Debug public ip remove if not needed
resource "azurerm_public_ip" "centos_host_nic_public_ip" {
  depends_on = [var.centos_host_network_depends_on]

  # Create for each window os workstation
  for_each = var.workstations

  name                    = "centos-host-nic-public-ip-${each.value.index}"
  location                = each.value.location
  resource_group_name     = var.resource_group_name
  allocation_method       = "Static"
  sku                     = "Standard"
}

resource "azurerm_network_interface" "centos_host_nic" {
  depends_on = [var.centos_host_network_depends_on]

  # Create for each window os workstation
  for_each = var.workstations

  name                = "centos-host-${each.value.index}-nic"
  location            = each.value.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "centos-host-${each.value.index}-ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.workstation_subnet_ids[index(var.workstation_subnet_locations, each.value.location)]

    # Debug public ip remove if not needed
    public_ip_address_id          = azurerm_public_ip.centos_host_nic_public_ip[each.key].id
  }
}