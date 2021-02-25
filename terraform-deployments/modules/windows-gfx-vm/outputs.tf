/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "windows-gfx-vm-ids" {
  value = [for item in azurerm_windows_virtual_machine.windows-gfx-vm : item.id]
}

output "windows-gfx-vm-public-ips" {
  value = [for item in azurerm_windows_virtual_machine.windows-gfx-vm : item.public_ip_address]
}

output "windows-gfx-vm-private-ips" {
  value = [for item in azurerm_windows_virtual_machine.windows-gfx-vm : item.private_ip_address]
}

output "windows-gfx-vm-names" {
  value = [for item in azurerm_windows_virtual_machine.windows-gfx-vm : item.name]
}

output "windows-gfx-vm-size" {
  description = "The size of the vitual machine"
  value       = [for item in azurerm_windows_virtual_machine.windows-gfx-vm : item.size]
}

output "resource-group-name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}
