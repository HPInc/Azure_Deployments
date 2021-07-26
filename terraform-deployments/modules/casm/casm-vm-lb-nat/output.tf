/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "internal-ip" {
  value = azurerm_linux_virtual_machine.cas-mgr-vm.private_ip_address
}

output "subnet" {
  value = [azurerm_subnet.cas-mgr, azurerm_subnet_network_security_group_association.cas]
}

output "cas-association-id" {
  value = azurerm_network_interface_nat_rule_association.cas_association_ssh.id
}