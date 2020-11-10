/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  # Create a map of windows workstations where the key is the index from 0 - N and the value it the item object
  filtered_windows_workstations_list = [for item in var.workstations: item if item.workstation_os == "windows"]
  filtered_windows_workstations_list_counts = [
    for item in local.filtered_windows_workstations_list: [
        for ranged_item in range(item.count): [
          item
      ]
    ] 
  ]
  filtered_windows_workstations_map_no_count = zipmap(range(length(flatten(local.filtered_windows_workstations_list_counts))), flatten(local.filtered_windows_workstations_list_counts))
  filtered_windows_workstations_map = {
    for count, item in local.filtered_windows_workstations_map_no_count: "${item.workstation_os}_host_${count}" => {
      index            = tonumber(count),
      location         = item.location,
      prefix           = item.prefix,
      workstation_os   = item.workstation_os,
      vm_size          = item.vm_size,
      disk_type        = item.disk_type,
      disk_size        = item.disk_size,
      isGFXHost        = item.isGFXHost
    }
  }

  # Create a map of linux workstations where the key is the index from 0 - N and the value it the item object
  filtered_linux_workstations_list = [for item in var.workstations: item if item.workstation_os == "linux"]
  filtered_linux_workstations_list_counts = [
    for item in local.filtered_linux_workstations_list: [
        for ranged_item in range(item.count): [
          item
      ]
    ] 
  ]
  filtered_linux_workstations_map_no_count= zipmap(range(length(flatten(local.filtered_linux_workstations_list_counts))), flatten(local.filtered_linux_workstations_list_counts))
  filtered_linux_workstations_map = {
    for count, item in local.filtered_linux_workstations_map_no_count: "${item.workstation_os}_host_${count}" => {
      index            = tonumber(count),
      location         = item.location,
      prefix           = item.prefix,
      workstation_os   = item.workstation_os,
      vm_size          = item.vm_size,
      disk_type        = item.disk_type,
      disk_size        = item.disk_size,
      isGFXHost        = item.isGFXHost
    }
  }

  # Figure out the unique locations/regions and from that create a list of virtual network regions and virtual network peer to peer links
  all_locations = [for item in var.workstations: item.location]
  vnet_locations = distinct(local.all_locations)

  peer_to_peer_vnet_links = length(local.vnet_locations) > 1 ? slice(local.vnet_locations, 1, length(local.vnet_locations)) : []
}
