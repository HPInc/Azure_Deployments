/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "centos-host-vm-ids" {
  value = [for item in azurerm_linux_virtual_machine.centos-std-vm : item.id]
}

/*output "centos-host-vm-public-ips" {
  value = [for item in azurerm_linux_virtual_machine.centos-std-vm : item.public_ip_address]
}

output "centos-host-vm-names" {
  value = [for item in azurerm_linux_virtual_machine.centos-std-vm : item.name]
}*/

output "centos-host-vm-private-ips" {
  value = [for item in azurerm_linux_virtual_machine.centos-std-vm : item.private_ip_address]
}

output "centos-host-vm-size" {
  description = "The size of the vitual machine"
  value       = [for item in azurerm_linux_virtual_machine.centos-std-vm : item.size]
}

output "resource-group-name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}
