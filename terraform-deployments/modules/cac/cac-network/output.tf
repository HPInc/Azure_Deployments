/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "cac-network-interface-ids" {
  description = "The cac network ids"
  value       = [for item in azurerm_network_interface.cac_nic : item.id]
}

output "cac-network-interface-primary-config-name" {
  description = "List of private ip addresses for the cac VMs"
  value       = [for item in azurerm_network_interface.cac_nic : item.ip_configuration[0].name]
}

output "cac-private-ips" {
  description = "List of private ip addresses for the cac VMs"
  value       = [for item in azurerm_network_interface.cac_nic : item.ip_configuration[0].private_ip_address]
}

output "cac-public-ips" {
  description = "List of public ip addresses for the cac VMs"
  value       = [for item in azurerm_public_ip.cac : item.ip_address]
}
