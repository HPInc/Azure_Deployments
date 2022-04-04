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

resource "azurerm_lb" "main" {
  resource_group_name = var.resource_group_name
  name                = "${local.prefix}loadbalancer-${var.location}"
  location            = var.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "loadbalancer_public_ip"
    public_ip_address_id = azurerm_public_ip.loadbalancer_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "backend-address-pool"
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {

  count = var.instance_count

  network_interface_id    = var.cac_network_interface_ids[count.index]
  ip_configuration_name   = "primary"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_lb_probe" "main" {
  loadbalancer_id     = azurerm_lb.main.id
  name                = var.probe_name
  port                = var.probe_port
  protocol            = var.probe_protocol
  request_path        = var.probe_path
  interval_in_seconds = 30
  number_of_probes    = 10
}

# Debug port to allow ssh access
resource "azurerm_lb_rule" "allow_port_22" {

  count = var.create_debug_ssh_access ? 1 : 0

  loadbalancer_id                = azurerm_lb.main.id
  name                           = "allow-ssh-${var.location}"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_lb.main.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.main.id
  load_distribution              = "SourceIPProtocol"
}

resource "azurerm_lb_rule" "allow_port_443" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "allow-https-${var.location}"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = azurerm_lb.main.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.main.id
  load_distribution              = "SourceIPProtocol"
}

resource "azurerm_lb_rule" "allow_port_4172" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "allow-4172-${var.location}"
  protocol                       = "Tcp"
  frontend_port                  = 4172
  backend_port                   = 4172
  frontend_ip_configuration_name = azurerm_lb.main.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.main.id
  load_distribution              = "SourceIPProtocol"
}

resource "azurerm_lb_rule" "allow_port_4172_udp" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "allow-4172-udp-${var.location}"
  protocol                       = "Udp"
  frontend_port                  = 4172
  backend_port                   = 4172
  frontend_ip_configuration_name = azurerm_lb.main.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.main.id
  load_distribution              = "SourceIPProtocol"
}

resource "azurerm_lb_rule" "allow_port_60443" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "allow-60443-${var.location}"
  protocol                       = "Tcp"
  frontend_port                  = 60443
  backend_port                   = 60443
  frontend_ip_configuration_name = azurerm_lb.main.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.main.id
  load_distribution              = "SourceIPProtocol"
}
