/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "windows-std-workstations" {
  value = local.windows_std_workstations_map
}

output "windows-gfx-workstations" {
  value = local.windows_gfx_workstations_map
}

output "centos-workstations" {
  value = local.centos_workstations_map
}

output "centos-std-workstations" {
  value = local.centos_std_workstations_map
}

output "centos-gfx-workstations" {
  value = local.centos_gfx_workstations_map
}

output "virtual-network-locations" {
  description = "A list of regions for virtual network creation based on the regions workstations reside in"
  value       = local.vnet_locations
}

output "virtual-network-peer-to-peer-links" {
  description = "A list of links that should be created for virtual networks based on the regions workstations reside in"
  value       = local.peer_to_peer_vnet_links
}
