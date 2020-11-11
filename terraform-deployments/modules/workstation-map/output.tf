/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "windows-workstations" {
  value = local.filtered_windows_workstations_map
}

output "linux-workstations" {
  value = local.filtered_linux_workstations_map
}

output "virtual-network-locations" {
  description = "A list of regions for virtual network creation based on the regions workstations reside in"
  value       = local.vnet_locations
}

output "virtual-network-peer-to-peer-links" {
  description = "A list of links that should be created for virtual networks based on the regions workstations reside in"
  value       = local.peer_to_peer_vnet_links
}
