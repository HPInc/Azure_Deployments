/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "internal-ip" {
  value = azurerm_linux_virtual_machine.cas-mgr-vm.private_ip_address
}

output "cidr" {
  value = var.cas_mgr_subnet_cidr[0]
}

output "subnet" {
  value = azurerm_subnet.cas-mgr
}

output "subnet-cas-id" {
  description = "The CAS Manager network subnet id"
  value       = azurerm_subnet.cas-mgr.id
}

# output "public-ip" {
#   value = azurerm_public_ip.cas-mgr-public.ip_address
# }

# output "cas-association-id" {
#   value = azurerm_network_interface_nat_rule_association.cas_association.id
# }