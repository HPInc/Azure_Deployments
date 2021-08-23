/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "cac-vm-ids" {
  description = "The id of the cac vitual machine"
  value       = [for item in azurerm_linux_virtual_machine.cac : item.id]
}

output "cac-vm-public-ips" {
  value = [for item in azurerm_linux_virtual_machine.cac : item.public_ip_address]
}

output "cac-vm-private-ips" {
  value = [for item in azurerm_linux_virtual_machine.cac : item.private_ip_address]
}

output "cac-vm-names" {
  description = "The name of the cac virtual machine"
  value       = [for item in azurerm_linux_virtual_machine.cac : item.name]
}

output "cac-vm-locations" {
  description = "The location of the cac vitual machine"
  value       = [for item in azurerm_linux_virtual_machine.cac : item.location]
}

output "cac-vm-size" {
  description = "The size of the cac vitual machine"
  value       = [for item in azurerm_linux_virtual_machine.cac : item.size]
}

output "machine-type" {
  description = "Machine type for Domain Controller"
  value       = var.machine_type
}

output "resource-group-name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}

output "cac-outbound" {
  value = azurerm_lb_outbound_rule.cac_outbound
}

output "cac-ssh" {
  value = azurerm_network_interface_nat_rule_association.cac_association_ssh
}