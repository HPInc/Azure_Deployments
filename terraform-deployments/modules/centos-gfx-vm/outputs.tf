/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "centos-gfx-vm-public-ips" {
  value = var.managed_identity_id != "" ? [for item in azurerm_linux_virtual_machine.centos-gfx-vm-im : item.public_ip_address] : [for item in azurerm_linux_virtual_machine.centos-gfx-vm-sp : item.public_ip_address]
}

output "centos-gfx-vm-private-ips" {
  value = var.managed_identity_id != "" ? [for item in azurerm_linux_virtual_machine.centos-gfx-vm-im : item.private_ip_address] : [for item in azurerm_linux_virtual_machine.centos-gfx-vm-sp : item.private_ip_address]
}

output "centos-gfx-vm-names" {
  value = var.managed_identity_id != "" ? [for item in azurerm_linux_virtual_machine.centos-gfx-vm-im : item.name] : [for item in azurerm_linux_virtual_machine.centos-gfx-vm-sp : item.name]
}
