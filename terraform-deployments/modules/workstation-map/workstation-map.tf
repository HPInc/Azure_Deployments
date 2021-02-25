/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  # Create a map of ALL Windows workstations where the key is the index from 0 - N and the value it the item object
  windows_workstations_list = [for item in var.workstations : item if item.workstation_os == "windows"]
  windows_workstations_list_counts = [
    for item in local.windows_workstations_list : [
      for ranged_item in range(item.count) : [
        item
      ]
    ]
  ]
  windows_workstations_map_no_count = zipmap(range(length(flatten(local.windows_workstations_list_counts))), flatten(local.windows_workstations_list_counts))
  windows_workstations_map = {
    for count, item in local.windows_workstations_map_no_count : "${item.workstation_os}_host_${count}" => {
      index          = tonumber(count),
      location       = item.location,
      prefix         = item.prefix,
      workstation_os = item.workstation_os,
      vm_size        = item.vm_size,
      disk_type      = item.disk_type,
      disk_size      = item.disk_size,
      isGFXHost      = item.isGFXHost
    }
  }

  # Create a map of Standard Windows workstations where the key is the index from 0 - N and the value it the item object
  windows_std_workstations_list = [for item in var.workstations : item if item.workstation_os == "windows" && item.isGFXHost == false]
  windows_std_workstations_list_counts = [
    for item in local.windows_std_workstations_list : [
      for ranged_item in range(item.count) : [
        item
      ]
    ]
  ]
  windows_std_workstations_map_no_count = zipmap(range(length(flatten(local.windows_std_workstations_list_counts))), flatten(local.windows_std_workstations_list_counts))
  windows_std_workstations_map = {
    for count, item in local.windows_std_workstations_map_no_count : "${item.workstation_os}_std_${count}" => {
      index          = tonumber(count),
      location       = item.location,
      prefix         = item.prefix,
      workstation_os = item.workstation_os,
      vm_size        = item.vm_size,
      disk_type      = item.disk_type,
      disk_size      = item.disk_size,
      isGFXHost      = item.isGFXHost
    }
  }

  # Create a map of Standard Windows workstations where the key is the index from 0 - N and the value it the item object
  windows_gfx_workstations_list = [for item in var.workstations : item if item.workstation_os == "windows" && item.isGFXHost == true]
  windows_gfx_workstations_list_counts = [
    for item in local.windows_gfx_workstations_list : [
      for ranged_item in range(item.count) : [
        item
      ]
    ]
  ]
  windows_gfx_workstations_map_no_count = zipmap(range(length(flatten(local.windows_gfx_workstations_list_counts))), flatten(local.windows_gfx_workstations_list_counts))
  windows_gfx_workstations_map = {
    for count, item in local.windows_gfx_workstations_map_no_count : "${item.workstation_os}_gfx_${count}" => {
      index          = tonumber(count),
      location       = item.location,
      prefix         = item.prefix,
      workstation_os = item.workstation_os,
      vm_size        = item.vm_size,
      disk_type      = item.disk_type,
      disk_size      = item.disk_size,
      isGFXHost      = item.isGFXHost
    }
  }

  # Create a map of ALL CentOS workstations where the key is the index from 0 - N and the value it the item object
  centos_workstations_list = [for item in var.workstations : item if item.workstation_os == "linux"]
  centos_workstations_list_counts = [
    for item in local.centos_workstations_list : [
      for ranged_item in range(item.count) : [
        item
      ]
    ]
  ]
  centos_workstations_map_no_count = zipmap(range(length(flatten(local.centos_workstations_list_counts))), flatten(local.centos_workstations_list_counts))
  centos_workstations_map = {
    for count, item in local.centos_workstations_map_no_count : "${item.workstation_os}_host_${count}" => {
      index          = tonumber(count),
      location       = item.location,
      prefix         = item.prefix,
      workstation_os = item.workstation_os,
      vm_size        = item.vm_size,
      disk_type      = item.disk_type,
      disk_size      = item.disk_size,
      isGFXHost      = item.isGFXHost
    }
  }

  # Create a map of Standard CentOS workstations where the key is the index from 0 - N and the value it the item object
  centos_std_workstations_list = [for item in var.workstations : item if item.workstation_os == "linux" && item.isGFXHost == false]
  centos_std_workstations_list_counts = [
    for item in local.centos_std_workstations_list : [
      for ranged_item in range(item.count) : [
        item
      ]
    ]
  ]
  centos_std_workstations_map_no_count = zipmap(range(length(flatten(local.centos_std_workstations_list_counts))), flatten(local.centos_std_workstations_list_counts))
  centos_std_workstations_map = {
    for count, item in local.centos_std_workstations_map_no_count : "${item.workstation_os}_std_${count}" => {
      index          = tonumber(count),
      location       = item.location,
      prefix         = item.prefix,
      workstation_os = item.workstation_os,
      vm_size        = item.vm_size,
      disk_type      = item.disk_type,
      disk_size      = item.disk_size,
      isGFXHost      = item.isGFXHost
    }
  }

  # Create a map of Graphics CentOS workstations where the key is the index from 0 - N and the value it the item object
  centos_gfx_workstations_list = [for item in var.workstations : item if item.workstation_os == "linux" && item.isGFXHost == true]
  centos_gfx_workstations_list_counts = [
    for item in local.centos_gfx_workstations_list : [
      for ranged_item in range(item.count) : [
        item
      ]
    ]
  ]
  centos_gfx_workstations_map_no_count = zipmap(range(length(flatten(local.centos_gfx_workstations_list_counts))), flatten(local.centos_gfx_workstations_list_counts))
  centos_gfx_workstations_map = {
    for count, item in local.centos_gfx_workstations_map_no_count : "${item.workstation_os}_gfx_${count}" => {
      index          = tonumber(count),
      location       = item.location,
      prefix         = item.prefix,
      workstation_os = item.workstation_os,
      vm_size        = item.vm_size,
      disk_type      = item.disk_type,
      disk_size      = item.disk_size,
      isGFXHost      = item.isGFXHost
    }
  }

  # Figure out the unique locations/regions and from that create a list of virtual network regions and virtual network peer to peer links
  all_locations  = [for item in var.workstations : item.location]
  vnet_locations = distinct(local.all_locations)

  peer_to_peer_vnet_links = length(local.vnet_locations) > 1 ? slice(local.vnet_locations, 1, length(local.vnet_locations)) : []
}
