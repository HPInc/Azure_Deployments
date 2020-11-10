/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "windows-host-vm-ids" {
  value = [for item in azurerm_windows_virtual_machine.windows_host : item.id]
}

output "windows-host-vm-public-ips" {
  value = [for item in azurerm_windows_virtual_machine.windows_host : item.public_ip_address]
}

output "windows-host-vm-private-ips" {
  value = [for item in azurerm_windows_virtual_machine.windows_host : item.private_ip_address]
}

output "windows-host-vm-names" {
  value = [for item in azurerm_windows_virtual_machine.windows_host : item.name]
}

output "windows-host-vm-size" {
  description = "The size of the vitual machine"
  value       = [for item in azurerm_windows_virtual_machine.windows_host : item.size]
}

output "resource-group-name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}
