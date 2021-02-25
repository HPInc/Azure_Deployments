/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "workstations" {
  description = "List of workstation types to create"
  type = map(object({
    index          = number # The index of this object in the map
    prefix         = string # The prefix applied to each VM name
    location       = string # The region this set will be deployed in
    workstation_os = string # The OS type for this VM "windows" or "linux"
    vm_size        = string # Valid VM size for the region selected
    disk_type      = string # Valid VM disk size
    disk_size      = string # Disk size of the VM in (GB)
    isGFXHost      = bool   # High end graphics VM host indicator for the installation of graphics drivers
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

variable "domain_name" {
  description = "Name of the domain to join"
  type        = string
}

variable "domain_controller_ip" {
  description = "Internal IP of the Domain Controller"
  type        = string
}

variable "ad_service_account_password" {
  description = "Active Directory Service Account password"
  type        = string
}

variable "ad_service_account_username" {
  description = "Active Directory Service Account username"
  type        = string
}

variable "application_id" {
  description = "The application (client) ID of your app registration in AAD"
  type        = string
}

variable "tenant_id" {
  description = "The directory (tenant) ID of your app registration in AAD"
  type        = string
}

variable "aad_client_secret" {
  description = "The client secret of your app registration in AAD"
  type        = string
}

variable "pcoip_registration_code" {
  description = "PCoIP Registration code from Teradici"
  type        = string
}

variable "workstation_subnet_ids" {
  description = "Workstations Subnet IDs"
}

variable "workstation_subnet_locations" {
  description = "Workstation subnet locations"
}

variable "key_vault_id" {
  description = "Key vault ID for ad admin password"
}

variable "ad_pass_secret_name" {
  description = "Name of ad admin password"
}
