/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  resource_group_name        = var.resource_group_name != "" ? var.resource_group_name : "casm_tf_one_ip_${random_id.string.hex}"
  cas_mgr_deployment_sa_file = "az-sa-key.json"
  prefixCounts = sort([ for r in data.azurerm_virtual_network.vnet_peerings: split(".","${r.address_space[0]}")[1]])
  prefix       = [for x in range(255): tostring(x) if !contains(local.prefixCounts, tostring(x)) && split(".","${data.azurerm_virtual_network.aadds_vnet.address_space[0]}")[1] != tostring(x)]
  vnet_cidr    = var.aadds_vnet_cidr == "" ? "10.${local.prefix[0]}.0.0/16" : var.aadds_vnet_cidr
}

data "azurerm_virtual_network" "aadds_vnet" {
  name                 = var.aadds_vnet_name
  resource_group_name  = var.aadds_vnet_rg
}

data "azurerm_virtual_network" "vnet_peerings" {
   for_each = data.azurerm_virtual_network.aadds_vnet.vnet_peerings
   name = split("/", each.value)[index(split("/", each.value), "virtualNetworks") + 1]
   resource_group_name = split("/", each.value)[index(split("/", each.value), "resourceGroups") + 1]
}

resource "azurerm_resource_group" "main" {
  location = module.workstation-map.virtual-network-locations[0]
  name     = local.resource_group_name
}

resource "random_id" "string" {
  byte_length = 3
}

resource "azurerm_storage_account" "storage" {
  name                            = "winscripts${random_id.string.hex}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = true
}

resource "azurerm_storage_container" "blob" {
  name                  = azurerm_storage_account.storage.name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "blob"
}

resource "azurerm_storage_container" "private-container" {
  name                  = "privatecontainer${random_id.string.hex}"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}
