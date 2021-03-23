/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "vnet_name" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
  default     = "vnet"
}

variable "ad_admin_username" {
  description = "Username for the Domain Administrator user"
  default     = "cas_admin"
}

variable "cac_admin_username" {
  description = "Username of the Cloud Access Connector Administrator"
  default     = "cas_admin"
}

variable "windows_admin_username" {
  description = "Name for the Windows Administrator of the Workstation"
  default     = "windows_admin"
}

variable "centos_admin_username" {
  description = "Name for the CentOS Administrator of the Workstation"
  default     = "centos_admin"
}

variable "active_directory_netbios_name" {
  description = "The netbios name of the Active Directory domain, for example `consoto`"
  default     = "tera"
}

variable "domain_group" {
  description = "Active Directory Distinguished Name for the User Group to log into the CAM Management Interface. Default is 'Domain Admins'. (eg, 'CN=CAM Admins,CN=Users,DC=example,DC=com')"
  default     = "Domain Admins"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  default     = ""
}

variable "cac_machine_type" {
  description = "Machine type for the Cloud Access Connector"
  default     = "Standard_D2s_v3"
}

variable "ssl_key" {
  description = "SSL private key for the Connector"
  default     = ""
}

variable "ssl_cert" {
  description = "SSL certificate for the Connector"
  default     = ""
}

variable "dc_machine_type" {
  description = "Machine type for Domain Controller"
  default     = "Standard_F2"
}

variable "ad_domain_users_list_file" {
  description = "Active Directory users to create, in CSV format"
  type        = string
  default     = ""
}

variable "create_debug_rdp_access" {
  description = "Debug flag to create RDP access to the domain controller"
  type        = bool
  default     = false
}

variable "ad_pass_secret_name" {
  description = "The name of the Active Directory secret password"
  type        = string
  default     = ""
}

variable "key_vault_id" {
  description = "The key vault resource ID"
  type        = string
  default     = ""
}

variable "tenant_id" {
  description = "The directory (tenant) ID of your app registration in AAD"
  type        = string
  default     = ""
}

variable "prefix" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
  default     = ""
}

variable "lls_instance_count" {
  description = "Number of PCoIP License Servers"
  default     = 1
}

variable "lls_license_count" {
  description = "Number of PCoIP session licenses to activate"
  default     = 0
}

variable "enable_workstation_idle_shutdown" {
  description = "Enable auto idle shutdown for Workstations"
  default     = true
}

variable "minutes_idle_before_shutdown" {
  description = "Minimum idle time for Workstations before auto idle shutdown, must be between 5 and 10000"
  default     = 240
}

variable "minutes_cpu_polling_interval" {
  description = "Polling interval for checking CPU utilization to determine if machine is idle, must be between 1 and 60"
  default     = 15
}
