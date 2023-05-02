/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "windows-std-vm-ids" {
  value = var.managed_identity_id != "" ? [for item in azurerm_windows_virtual_machine.windows-std-vm-im : item.id] : [for item in azurerm_windows_virtual_machine.windows-std-vm-sp : item.id]
}

output "windows-std-vm-public-ips" {
  value = var.managed_identity_id != "" ? [for item in azurerm_windows_virtual_machine.windows-std-vm-im : item.public_ip_address] : [for item in azurerm_windows_virtual_machine.windows-std-vm-sp : item.public_ip_address]
}

output "windows-std-vm-private-ips" {
  value = var.managed_identity_id != "" ? [for item in azurerm_windows_virtual_machine.windows-std-vm-im : item.private_ip_address] : [for item in azurerm_windows_virtual_machine.windows-std-vm-sp : item.private_ip_address]
}

output "windows-std-vm-names" {
  value = var.managed_identity_id != "" ? [for item in azurerm_windows_virtual_machine.windows-std-vm-im : item.name] : [for item in azurerm_windows_virtual_machine.windows-std-vm-sp : item.name]
}

output "windows-std-vm-size" {
  description = "The size of the vitual machine"
  value       = var.managed_identity_id != "" ? [for item in azurerm_windows_virtual_machine.windows-std-vm-im : item.size]: [for item in azurerm_windows_virtual_machine.windows-std-vm-sp : item.size]
}

output "resource-group-name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}
