/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "cac-public-ip" {
  value = azurerm_public_ip.cac.*.ip_address
}

output "network-interface-ids" {
  value = azurerm_network_interface.cac-nic.*.id
}

output "cac-vm-names" {
  value = azurerm_linux_virtual_machine.cac-vm.*.name
}

output "cac-subnet-ids" {
  value = azurerm_subnet.cac.id
}