/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "cac-vm-ids" {
  description = "The id of the cac vitual machine"
  value       = var.managed_identity_id != "" ? [for item in azurerm_linux_virtual_machine.cac-im : item.id] : [for item in azurerm_linux_virtual_machine.cac-sp : item.id]
}

output "cac-vm-public-ips" {
  value = var.managed_identity_id != "" ? [for item in azurerm_linux_virtual_machine.cac-im : item.public_ip_address] : [for item in azurerm_linux_virtual_machine.cac-sp : item.public_ip_address]
}

output "cac-vm-private-ips" {
  value = var.managed_identity_id != "" ? [for item in azurerm_linux_virtual_machine.cac-im : item.private_ip_address] : [for item in azurerm_linux_virtual_machine.cac-sp : item.private_ip_address]
}

output "cac-vm-names" {
  description = "The name of the cac virtual machine"
  value       = var.managed_identity_id != "" ? [for item in azurerm_linux_virtual_machine.cac-im : item.name] : [for item in azurerm_linux_virtual_machine.cac-sp : item.name]
}

output "cac-vm-locations" {
  description = "The location of the cac vitual machine"
  value       = var.managed_identity_id != "" ? [for item in azurerm_linux_virtual_machine.cac-im : item.location] : [for item in azurerm_linux_virtual_machine.cac-sp : item.location]
}

output "cac-vm-size" {
  description = "The size of the cac vitual machine"
  value       = var.managed_identity_id != "" ? [for item in azurerm_linux_virtual_machine.cac-im : item.size] : [for item in azurerm_linux_virtual_machine.cac-sp : item.size]
}

output "machine-type" {
  description = "Machine type for Domain Controller"
  value       = var.machine_type
}

output "resource-group-name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}
