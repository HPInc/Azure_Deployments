/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "centos-gfx-vm-public-ips" {
  value = [for item in azurerm_linux_virtual_machine.centos-gfx-vm : item.public_ip_address]
}

output "centos-gfx-vm-private-ips" {
  value = [for item in azurerm_linux_virtual_machine.centos-gfx-vm : item.private_ip_address]
}

output "centos-gfx-vm-names" {
  value = [for item in azurerm_linux_virtual_machine.centos-gfx-vm : item.name]
}
