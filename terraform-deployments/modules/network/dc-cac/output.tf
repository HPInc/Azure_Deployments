/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "dc-private-ip" {
  description = "The domain controller private ip address"
  value       = azurerm_network_interface.dc_nic.ip_configuration[0].private_ip_address
}

output "dc-public-ip" {
  description = "The domain controller public ip address"
  value       = azurerm_public_ip.dc_ip.ip_address
}

output "dc-network-interface-id" {
  description = "The domain controller network id"
  value       = azurerm_network_interface.dc_nic.id
}

output "network-security-group-ids" {
  description = "The domain controller network security group id"
  value       = [for item in azurerm_network_security_group.nsg : item.id]
}

output "subnet-dc-id" {
  description = "The domain controller network subnet id"
  value       = azurerm_subnet.dc.id
}

output "subnet-workstation-ids" {
  description = "The workstation network subnet id"
  value       = [for item in azurerm_subnet.workstation : item.id]
}

output "subnet-workstation-names" {
  description = "The workstation network subnet name"
  value       = [for item in azurerm_subnet.workstation : item.name]
}

output "subnet-workstation-locations" {
  description = "The workstation network subnet locations"
  # workstation location subnet is created one per virtual network so the subnet locations match
  value = [for item in azurerm_virtual_network.network : item.location]
}

output "private-dns-zone-id" {
  value = azurerm_private_dns_zone.dns.id
}

output "virtual-network-names" {
  value = [for item in azurerm_virtual_network.network : item.name]
}

output "nat-gateway-ids" {
  value = [for item in azurerm_nat_gateway.nat : item.id]
}

output "all-output" {
  description = "An output value following modules can use as a dependency and be sure all resouces are created beforehand"
  value       = {}

  # Anything that refers to this output must wait until the actions for this module have completed first
  depends_on = [
    azurerm_network_interface.dc_nic,
    azurerm_public_ip.dc_ip,
    azurerm_network_security_group.nsg,
    azurerm_subnet.dc,
    azurerm_subnet.workstation,
    azurerm_subnet_network_security_group_association.network,
    azurerm_virtual_network.network,
    azurerm_private_dns_srv_record.dns-win,
    azurerm_private_dns_srv_record.dns-ldaps,
    azurerm_network_security_rule.nsg_allow_all_vnet
  ]
}

output "resource-group-name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}

output "virtual-network-name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.network[0].name
}
