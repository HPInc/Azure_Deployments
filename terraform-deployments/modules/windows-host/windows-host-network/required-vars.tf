/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "workstations" {
  description = "List of workstation types to create"
  type        = map(object({
      index            = number # The index of this object in the map
      prefix           = string # The prefix applied to each VM name
      location         = string # The region this set will be deployed in
      workstation_os   = string # The OS type for this VM "windows" or "linux"
      vm_size          = string # Valid VM size for the region selected
      disk_type        = string # Valid VM disk type
      disk_size        = number # The size of the VM disk in GB
      isGFXHost        = bool   # High end graphics VM host indicator for the installation of graphics drivers
    }))
}

variable "resource_group_name" {
  description = "Basename of the Resource Group to deploy the workstation"
  type        = string
}

variable "workstation_subnet_ids" {
  description = "List of workstation subnets for each location"
  type        = list(string)
}

variable "workstation_subnet_locations" {
  description = "List of workstation locations"
  type        = list(string)
}

variable "nat_gateway_ids" {
  description = "List of gateway ids for each locations"
  type        = list(string)
}

