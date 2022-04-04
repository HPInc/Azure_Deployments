/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

resource "azurerm_public_ip" "loadbalancer_public_ip" {
  count = length(var.locations)

  name                    = "public-loadbalancer-ip-${var.locations[count.index]}"
  location                = var.locations[count.index]
  resource_group_name     = var.resource_group_name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  sku                     = "Standard"
}

resource "azurerm_lb" "main" {
  count = length(var.locations)

  name                = "${var.prefix}-loadbalancer-${var.locations[count.index]}"
  location            = var.locations[count.index]
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "loadbalancer_public_ip"
    public_ip_address_id = azurerm_public_ip.loadbalancer_public_ip[count.index].id
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  count = length(var.locations)

  loadbalancer_id = azurerm_lb.main[count.index].id
  name            = "backend-address-pool"
}

# Optional load balancer vm association
resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count = length(var.cac_configuration)

  network_interface_id    = var.cac_network_interface_ids[count.index]
  ip_configuration_name   = var.cac_network_interface_primary_config_name[count.index]
  backend_address_pool_id = azurerm_lb_backend_address_pool.main[index(var.locations, var.cac_configuration[count.index].location)].id
}

resource "azurerm_lb_probe" "main" {
  count = length(var.locations)

  loadbalancer_id     = azurerm_lb.main[count.index].id
  name                = var.probe_name
  port                = var.probe_port
  protocol            = var.probe_protocol
  request_path        = var.probe_path
  interval_in_seconds = 30
  number_of_probes    = 10
}

# Debug port to allow ssh access
resource "azurerm_lb_rule" "allow_port_22" {
  count = var.create_debug_ssh_access ? length(var.locations) : 0

  loadbalancer_id                = azurerm_lb.main[count.index].id
  name                           = "allow-ssh-${var.locations[count.index]}"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_lb.main[count.index].frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main[count.index].id]
  probe_id                       = azurerm_lb_probe.main[count.index].id
  load_distribution              = "SourceIPProtocol"
}

resource "azurerm_lb_rule" "allow_port_443" {
  count = length(var.locations)

  loadbalancer_id                = azurerm_lb.main[count.index].id
  name                           = "allow-https-${var.locations[count.index]}"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = azurerm_lb.main[count.index].frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main[count.index].id]
  probe_id                       = azurerm_lb_probe.main[count.index].id
  load_distribution              = "SourceIPProtocol"
}

resource "azurerm_lb_rule" "allow_port_4172" {
  count = length(var.locations)

  loadbalancer_id                = azurerm_lb.main[count.index].id
  name                           = "allow-4172-${var.locations[count.index]}"
  protocol                       = "Tcp"
  frontend_port                  = 4172
  backend_port                   = 4172
  frontend_ip_configuration_name = azurerm_lb.main[count.index].frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main[count.index].id]
  probe_id                       = azurerm_lb_probe.main[count.index].id
  load_distribution              = "SourceIPProtocol"
}

resource "azurerm_lb_rule" "allow_port_4172_udp" {
  count = length(var.locations)

  loadbalancer_id                = azurerm_lb.main[count.index].id
  name                           = "allow-4172-udp-${var.locations[count.index]}"
  protocol                       = "Udp"
  frontend_port                  = 4172
  backend_port                   = 4172
  frontend_ip_configuration_name = azurerm_lb.main[count.index].frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main[count.index].id]
  probe_id                       = azurerm_lb_probe.main[count.index].id
  load_distribution              = "SourceIPProtocol"
}

resource "azurerm_lb_rule" "allow_port_60443" {
  count = length(var.locations)

  loadbalancer_id                = azurerm_lb.main[count.index].id
  name                           = "allow-60443-${var.locations[count.index]}"
  protocol                       = "Tcp"
  frontend_port                  = 60443
  backend_port                   = 60443
  frontend_ip_configuration_name = azurerm_lb.main[count.index].frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main[count.index].id]
  probe_id                       = azurerm_lb_probe.main[count.index].id
  load_distribution              = "SourceIPProtocol"
}
