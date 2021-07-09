/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

resource "azurerm_subnet" "fw-subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = var.fw_subnet_cidr
}

resource "azurerm_public_ip" "fw-frontend" {
  name                    = "public-ip-cac-${var.location}-fw-frontend"
  location                = var.location
  resource_group_name     = var.resource_group_name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  sku                     = "Standard"
}

resource "azurerm_public_ip" "dc_ip" {
  name                    = "public-dc-ip"
  location                = var.locations[0]
  resource_group_name     = var.resource_group_name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  sku                     = "Standard"
}

resource "azurerm_public_ip" "cac" {

  count = var.instance_count

  name                    = "public-ip-cac-${var.location}-${count.index}"
  location                = var.location
  resource_group_name     = var.resource_group_name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  sku                     = "Standard"
}

resource "azurerm_public_ip" "cas-mgr-public-ip" {
  name                = "cas-mgr-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "cac-fw" {
  name                = "cac-fw"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "ip-config-fw-frontend"
    subnet_id            = azurerm_subnet.fw-subnet.id
    public_ip_address_id = azurerm_public_ip.fw-frontend.id
  }

  ip_configuration {
    name                 = "ip-config-cas-frontend"
    public_ip_address_id = azurerm_public_ip.cas-mgr-public-ip.id
  }

  ip_configuration {
    name                 = "ip-config-dc-frontend"
    public_ip_address_id = azurerm_public_ip.dc_ip.id
  }

  dynamic "ip_configuration" {
    for_each = { for idx, val in azurerm_public_ip.cac: idx => val}
    content {
      name                 = "ip-config-${ip_configuration.key}"
      public_ip_address_id = ip_configuration.value.id
    }
  }
}