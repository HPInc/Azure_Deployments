/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

resource "azurerm_resource_group" "script" {
  location = var.location
  name     = var.resource_group_name
}

resource "azurerm_storage_account" "script" {
  name                     = azurerm_resource_group.script.name
  resource_group_name      = azurerm_resource_group.script.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "script" {
  name                  = azurerm_storage_account.script.name
  storage_account_name  = azurerm_storage_account.script.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "windows-std-provisioning-script" {
  name                   = "windows-std-provisioning.ps1"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/windows-std-provisioning.ps1"
}

resource "azurerm_storage_blob" "windows-gfx-provisioning-script" {
  name                   = "windows-gfx-provisioning.ps1"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/windows-gfx-provisioning.ps1"
}
