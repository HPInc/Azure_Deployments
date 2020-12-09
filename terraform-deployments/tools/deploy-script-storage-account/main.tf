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
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.script.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "script" {
  name                  = "${var.storage_account_name}container"
  storage_account_name  = azurerm_storage_account.script.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "script" {
  name                   = "${var.storage_account_name}blob"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
}

resource "azurerm_storage_blob" "sysprep-script" {
  name                   = "sysprep.ps1"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/sysprep.ps1"
}

resource "azurerm_storage_blob" "centos-provisioning-script" {
  name                   = "centos-provisioning.sh"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/centos-provisioning.sh"
}

resource "azurerm_storage_blob" "centos-gfx-provisioning-script" {
  name                   = "centos-gfx-provisioning.sh"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/centos-gfx-provisioning.sh"
}

resource "azurerm_storage_blob" "windows-std-script" {
  name                   = "DeployPCoIPAgent.ps1"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/DeployPCoIPAgent.ps1"
}

resource "azurerm_storage_blob" "pcoip-agent" {
  name                   = "pcoip-agent-standard_20.10.1.exe"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/pcoip-agent-standard_20.10.1.exe"
}

resource "azurerm_storage_blob" "background-img" {
  name                   = "img0.jpg"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/img0.jpg"
}
