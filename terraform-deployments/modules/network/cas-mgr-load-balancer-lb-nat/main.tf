/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  prefix = var.prefix != "" ? "${var.prefix}-" : ""
}

resource "azurerm_public_ip" "loadbalancer_public_ip" {
  resource_group_name     = var.resource_group_name
  name                    = "public-loadbalancer-ip-${var.location}"
  location                = var.location
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  sku                     = "Standard"
}

resource "azurerm_public_ip" "dc_ip" {
  name                    = "public-dc-ip"
  location                = var.location
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


resource "azurerm_lb" "main" {

  name                = "${var.prefix}-loadbalancer"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "loadbalancer-frontend"
    public_ip_address_id = azurerm_public_ip.loadbalancer_public_ip.id
  }

  frontend_ip_configuration {
    name                 = "ip-config-cas-frontend"
    public_ip_address_id = azurerm_public_ip.cas-mgr-public-ip.id
  }

  frontend_ip_configuration {
    name                 = "ip-config-dc-frontend"
    public_ip_address_id = azurerm_public_ip.dc_ip.id
  }

  dynamic "frontend_ip_configuration" {
    for_each = { for idx, val in azurerm_public_ip.cac: idx => val}
    content {
      name                 = "ip-config-cac-${frontend_ip_configuration.key}"
      public_ip_address_id = frontend_ip_configuration.value.id
    }
  }
}

resource "azurerm_lb_probe" "main" {
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.main.id
  name                = var.probe_name
  port                = var.probe_port
  protocol            = var.probe_protocol
  request_path        = var.probe_path
  interval_in_seconds = 30
  number_of_probes    = 10
}