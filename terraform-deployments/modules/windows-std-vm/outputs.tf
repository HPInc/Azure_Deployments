/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "windows-std-vm-ids" {
  value = [for item in azurerm_windows_virtual_machine.windows-std-vm : item.id]
}

output "windows-std-vm-public-ips" {
  value = [for item in azurerm_windows_virtual_machine.windows-std-vm : item.public_ip_address]
}

output "windows-std-vm-private-ips" {
  value = [for item in azurerm_windows_virtual_machine.windows-std-vm : item.private_ip_address]
}

output "windows-std-vm-names" {
  value = [for item in azurerm_windows_virtual_machine.windows-std-vm : item.name]
}

output "windows-std-vm-size" {
  description = "The size of the vitual machine"
  value       = [for item in azurerm_windows_virtual_machine.windows-std-vm : item.size]
}

output "resource-group-name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}
