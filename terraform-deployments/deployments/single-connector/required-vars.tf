/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "workstations" {
  description = "List of workstation types to create"
  type = list(object({
    prefix         = string # The prefix applied to each VM name
    location       = string # The region this set will be deployed in
    workstation_os = string # The OS type for this VM "windows" or "linux"
    vm_size        = string # Valid VM size for the region selected
    disk_type      = string # Valid VM disk type
    count          = number # The number of VMs of this type to create
    disk_size      = number # The size of the VM disk in GB
    isGFXHost      = bool   # High end graphics VM host indicator for the installation of graphics drivers
  }))
}

variable "cac_configuration" {
  description = "List of cac vrtual machines create"
  type = list(object({
    location  = string
    cac_token = string
  }))
}

variable "prefix" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
}

variable "resource_group_name" {
  description = "The name of the resource group"
}

variable "ad_admin_password" {
  description = "Password for the Adminstrator user"
}

variable "safe_mode_admin_password" {
  description = "Safe Mode Admin Password (Directory Service Restore Mode - DSRM)"
  type        = string
}

variable "ad_domain_users_list_file" {
  description = "Safe Mode Admin Password (Directory Service Restore Mode - DSRM)"
  type        = string
}

variable "_artifactsLocation" {
  description = "The base URI where artifacts required by this template are located including a trailing '/'"
  default     = ""
}

variable "pcoip_registration_code" {
  description = "PCoIP Registration code"
  type        = string
}
