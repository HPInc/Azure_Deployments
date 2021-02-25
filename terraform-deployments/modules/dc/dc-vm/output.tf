/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "domain-controller-id" {
  description = "The id of the domain controller instance"
  value = azurerm_windows_virtual_machine.domain-controller.id
}

output "domain-controller-name" {
  description = "The name of the domain controller instance"
  value = azurerm_windows_virtual_machine.domain-controller.name
}

output "dc-machine-type" {
  description = "Machine type for Domain Controller"
  value       = var.dc_machine_type
}

output "resource-group-name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}