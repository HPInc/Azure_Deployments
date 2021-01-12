/*
 * Copyright (c) 2020 Teradici Corporation
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
    disk_type      = string # Valid VM disk type
    disk_size      = number # The size of the VM disk in GB
    isGFXHost      = bool   # High end graphics VM host indicator for the installation of graphics drivers
  }))
}

variable "resource_group_name" {
  description = "The name of the resource group"
}

variable "domain_name" {
  description = "Name of the domain to join"
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

variable "pcoip_secret_id" {
  description = "The secret identifier in your azure key vault, follow this format https://<keyvault-name>.vault.azure.net/secrets/<secret-name>/<secret-version>"
  type        = string
}

variable "ad_pass_secret_id" {
  description = "The secret identifier in your azure key vault, follow this format https://<keyvault-name>.vault.azure.net/secrets/<secret-name>/<secret-version>"
  type        = string
}

variable "pcoip_registration_code" {
  description = "PCoIP Registration code from Teradici"
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

variable "workstation_subnet_ids" {
  description = "List of workstation subnets for each location"
  type        = list(string)
}

variable "workstation_subnet_locations" {
  description = "List of workstation locations"
  type        = list(string)
}

variable "key_vault_id" {
  description = "Key vault ID for ad admin password"
}

variable "ad_pass_secret_name" {
  description = "Name of ad admin password"
}

variable "storage_account_name" {
  description = "Name of storage account that holds Windows provisioning scripts"
}
