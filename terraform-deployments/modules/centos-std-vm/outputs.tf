/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "centos-std-vm-public-ips" {
  value = var.managed_identity_id != "" ? [for item in azurerm_linux_virtual_machine.centos-std-vm-im : item.public_ip_address] : [for item in azurerm_linux_virtual_machine.centos-std-vm-sp : item.public_ip_address]
}

output "centos-std-vm-names" {
  value = var.managed_identity_id != "" ? [for item in azurerm_linux_virtual_machine.centos-std-vm-im : item.name] : [for item in azurerm_linux_virtual_machine.centos-std-vm-sp : item.name]
}

output "centos-std-vm-private-ips" {
  value = var.managed_identity_id != "" ? [for item in azurerm_linux_virtual_machine.centos-std-vm-im : item.private_ip_address] : [for item in azurerm_linux_virtual_machine.centos-std-vm-sp : item.private_ip_address]
}
