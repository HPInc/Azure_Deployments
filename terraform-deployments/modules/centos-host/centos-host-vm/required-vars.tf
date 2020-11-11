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
      disk_type        = string # Valid VM disk size
      disk_size        = string # Disk size of the VM in (GB)
      isGFXHost        = bool   # High end graphics VM host indicator for the installation of graphics drivers
    }))
}

variable "resource_group_name" {
  description = "Basename of the Resource Group to deploy the workstation. Hostname will be <prefix>-<name>.Lower case only."
  type        = string
}

variable "admin_name" {
  description = "Name for the Administrator of the Workstation"
  type        = string
}

variable "admin_password" {
  description = "Password for the Administrator of the Workstation"
  type        = string
}

variable "centos_host_nic_ids" {
  description = "List of network card ids we will use to create the VMs"
  type = list(string)
}
