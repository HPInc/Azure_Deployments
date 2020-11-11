/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

 resource "azurerm_traffic_manager_profile" "main" {
  depends_on = [var.traffic_manager_depends_on]

  name                = var.resource_name
  resource_group_name = var.resource_group_name

  traffic_routing_method = "Weighted"

  dns_config {
    relative_name = var.dns_name
    ttl           = 100
  }

  monitor_config {
    protocol                     = var.profile_protocol
    port                         = var.profile_port
    path                         = var.profile_path
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }
}

resource "azurerm_traffic_manager_endpoint" "main" {
  count = length(var.managed_endpoints)

  name                = var.managed_endpoint_names[count.index]
  resource_group_name = var.resource_group_name
  profile_name        = azurerm_traffic_manager_profile.main.name
  target              = var.managed_endpoints[count.index]
  type                = "externalEndpoints"
  weight              = 100 + count.index
}
