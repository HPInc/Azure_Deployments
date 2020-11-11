/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

resource "azurerm_resource_group" "script" {
  location = var.location
  name     = "${var.resource_group_name}"
}

resource "azurerm_storage_account" "script" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.script.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "script" {
  depends_on            = [azurerm_storage_account.script]
  name                  = "${var.storage_account_name}container"
  storage_account_name  = azurerm_storage_account.script.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "script" {
  depends_on             = [azurerm_storage_container.script]
  name                   = "${var.storage_account_name}blob"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
}

resource "azurerm_storage_blob" "sysprep-script" {
  depends_on             = [azurerm_storage_container.script]
  name                   = "sysprep.ps1"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/sysprep.ps1" 
}

resource "azurerm_storage_blob" "centos-script-util" {
  depends_on             = [azurerm_storage_container.script]
  name                   = "centos-utility.sh"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/centos-utility.sh" 
}

resource "azurerm_storage_blob" "centos-script-stage1" {
  depends_on             = [azurerm_storage_container.script]
  name                   = "centos-startup-stage1.sh"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/centos-startup-stage1.sh" 
}

resource "azurerm_storage_blob" "centos-script-stage2" {
  depends_on             = [azurerm_storage_container.script]
  name                   = "centos-startup-stage2.sh"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/centos-startup-stage2.sh" 
}

resource "azurerm_storage_blob" "centos-gfx-script-stage1" {
  depends_on             = [azurerm_storage_container.script]
  name                   = "centos-gfx-install-stage1.sh"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/centos-gfx-install-stage1.sh" 
}

resource "azurerm_storage_blob" "centos-gfx-script-stage2" {
  depends_on             = [azurerm_storage_container.script]
  name                   = "centos-gfx-install-stage2.sh"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/centos-gfx-install-stage2.sh" 
}

resource "azurerm_storage_blob" "centos-gfx-script-stage3" {
  depends_on             = [azurerm_storage_container.script]
  name                   = "centos-gfx-install-stage3.sh"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/centos-gfx-install-stage3.sh"
}

resource "azurerm_storage_blob" "windows-std-script" {
  depends_on             = [azurerm_storage_container.script]
  name                   = "DeployPCoIPAgent.ps1"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/DeployPCoIPAgent.ps1" 
}

resource "azurerm_storage_blob" "pcoip-agent" {
  depends_on             = [azurerm_storage_container.script]
  name                   = "pcoip-agent-standard_19.11.0.exe"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/pcoip-agent-standard_19.11.0.exe" 
}

resource "azurerm_storage_blob" "background-img" {
  depends_on             = [azurerm_storage_container.script]
  name                   = "img0.jpg"
  storage_account_name   = azurerm_storage_account.script.name
  storage_container_name = azurerm_storage_container.script.name
  type                   = "Block"
  source                 = "${path.module}/img0.jpg" 
}