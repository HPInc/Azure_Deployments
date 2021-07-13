/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  resource_group_name        = var.resource_group_name != "" ? var.resource_group_name : "BY-casm_lb1ip_${random_id.string.hex}"
  cas_mgr_deployment_sa_file = "az-sa-key.json"
}

data "azurerm_virtual_network" "aadds_vnet" {
  name                 = var.aadds_vnet_name
  resource_group_name  = var.aadds_vnet_rg
}

resource "azurerm_resource_group" "main" {
  location = module.workstation-map.virtual-network-locations[0]
  name     = local.resource_group_name
}

resource "random_id" "string" {
  byte_length = 3
}

resource "azurerm_storage_account" "storage" {
  name                     = "winscripts${random_id.string.hex}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = true
}

resource "azurerm_storage_container" "blob" {
  depends_on = [azurerm_storage_account.storage]
  name                  = azurerm_storage_account.storage.name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "blob"
}

resource "azurerm_storage_container" "private-container" {
  depends_on = [azurerm_storage_account.storage]
  name                  = "privatecontainer${random_id.string.hex}"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}
