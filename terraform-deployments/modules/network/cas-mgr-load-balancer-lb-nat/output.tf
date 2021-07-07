/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "public-ip" {
  description = "Load balancer IP addresses"
  value       = azurerm_public_ip.loadbalancer_public_ip.ip_address
}

output "load-balancer-ids" {
  description = "The created load balancer ids"
  value       = [azurerm_lb.main.id]
}

output "cac-public" {
  value = azurerm_public_ip.cac.*
}

output "dc-public" {
  value = azurerm_public_ip.dc_ip
}

output "cas-public" {
  value = azurerm_public_ip.cas-mgr-public-ip
}

output "probe-id" {
  value = azurerm_lb_probe.main.id
}