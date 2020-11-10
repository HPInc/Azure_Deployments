/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "windows-host-private-ips" {
  value = [for item in azurerm_network_interface.windows_host_nic : item.private_ip_address]
}

output "windows-host-nic-ids" {
  value = [for item in azurerm_network_interface.windows_host_nic : item.id]
}
