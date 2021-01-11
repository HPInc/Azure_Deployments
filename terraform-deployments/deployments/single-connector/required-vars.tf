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

variable "cac_installer_token" {
  description = "Token used to download cloud access connector installer."
}

variable "prefix" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
}

variable "resource_group_name" {
  description = "The name of the resource group"
}

variable "active_directory_netbios_name" {
  description = "The netbios name of the Active Directory domain, for example `consoto`"
}

variable "ad_admin_password" {
  description = "Password for the Adminstrator user"
  default     = ""
}

variable "ad_pass_secret_name" {
  description = "The name of the Active Directory secret password"
  type        = string
}

variable "key_vault_id" {
  description = "The key vault resource ID"
  type        = string
}

variable "application_id" {
  description = "The application (client) ID of your app registration in AAD"
  type        = string
}

variable "aad_client_secret" {
  description = "The client secret of your app registration in AAD"
  type        = string
}

variable "tenant_id" {
  description = "The directory (tenant) ID of your app registration in AAD"
  type        = string
}

variable "safe_admin_pass_secret_id" {
  description = "The secret identifier in your azure key vault, follow this format https://<keyvault-name>.vault.azure.net/secrets/<secret-name>/<secret-version>"
  type        = string
}

variable "safe_mode_admin_password" {
  description = "Safe Mode Admin Password (Directory Service Restore Mode - DSRM)"
  type        = string
  default     = ""
}

variable "ad_domain_users_list_file" {
  description = "Safe Mode Admin Password (Directory Service Restore Mode - DSRM)"
  type        = string
}

variable "cac_token_secret_id" {
  description = "The secret identifier in your azure key vault, follow this format https://<keyvault-name>.vault.azure.net/secrets/<secret-name>/<secret-version>"
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

variable "_artifactsLocation" {
  description = "The base URI where artifacts required by this template are located including a trailing '/'"
}

variable "pcoip_registration_code" {
  description = "PCoIP Registration code"
  type        = string
  default     = ""
}

variable "cac_admin_password" {
  description = "Password for the Administrator of the Cloud Access Connector VM"
  type        = string
}

variable "windows_admin_password" {
  description = "Password for the Administrator of the Workstation"
  type        = string
}

variable "centos_admin_password" {
  description = "Password for the Administrator of the Workstation"
  type        = string
}
