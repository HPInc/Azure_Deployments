/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "network-interface-ids" {
  value = azurerm_network_interface.cac-nic.*.id
}

output "cac-vm-names" {
  value = azurerm_linux_virtual_machine.cac-vm.*.name
}

output "cac-subnet-ids" {
  value = azurerm_subnet.cac.id
}

output "cac-nat-rules" {
  value = azurerm_firewall_nat_rule_collection.cac-fw-nat
}

output "cac-fw-rules" {
  value = azurerm_firewall_network_rule_collection.cac-fw-network
}