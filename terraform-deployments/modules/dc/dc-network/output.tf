/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "private-ip" {
  description = "The domain controller private ip address"
  value = azurerm_network_interface.dc_nic.ip_configuration[0].private_ip_address
}

output "public-ip" {
  description = "The domain controller public ip address"
  value = azurerm_public_ip.dc_ip.ip_address
}

output "network-interface-id" {
  description = "The domain controller network id"
  value = azurerm_network_interface.dc_nic.id
}

output "network-security-group-id" {
  description = "The domain controller network security group id"
  value = azurerm_network_security_group.nsg.id
}

output "subnet-dc-id" {
  description = "The domain controller network subnet id"
  value = azurerm_subnet.dc.id
}

output "subnet-workstation-id" {
  description = "The workstation network subnet id"
  value = azurerm_subnet.workstation.id
}

output "all-output" {
  description = "An output value following modules can use as a dependency and be sure all resouces are created beforehand"
  value = [
    azurerm_network_interface.dc_nic.id,
    azurerm_public_ip.dc_ip.id,
    azurerm_network_security_group.nsg.id,
    azurerm_subnet.dc.id,
    azurerm_subnet.workstation.id,
    azurerm_subnet_network_security_group_association.network.id,
    azurerm_virtual_network.network.id
  ]
}
