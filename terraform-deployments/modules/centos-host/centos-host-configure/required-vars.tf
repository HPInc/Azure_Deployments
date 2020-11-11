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
  description = "The name of the resource group"
}

variable "centos-host-vm-ids" {
  description = "List of VMs to configure"
  type        = list(string)
}

variable "centos-host-vm-public-ips" {
  description = "List of public ips of the VMs to configure"
  type        = list(string)
}

variable "centos-host-vm-names" {
  description = "List of names of the VMs to configure"
  type        = list(string)
}

variable "_artifactsLocation" {
  description = "URL to retrieve startup scripts with a trailing /"
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
  description = "Username of the VM created"
  type        = string
}

variable "admin_password" {
  description = "Password of the VM created"
  type        = string
}