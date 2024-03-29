/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  resource_group_name        = var.resource_group_name != "" ? var.resource_group_name : "cas_mgr_oneip_tf${random_id.string.hex}"
  cas_mgr_deployment_sa_file = "az-sa-key.json"
}

resource "azurerm_resource_group" "main" {
  location = var.cac_location_list[0]
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
  min_tls_version                 = "TLS1_0"
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
