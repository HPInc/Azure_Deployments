/*
 * Copyright (c) 2020 Teradici Corporation
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

variable "dc_subnet_name" {
  description = "Name for the subnet containing the Domain Controller."
  default     = "dc-subnet"
}

variable "workstation_subnet_name" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
  default     = "workstation-subnet"
}

variable "pcoip_agent_location" {
  description = "URL of Teradici PCoIP Standard Agent"
  default     = "https://downloads.teradici.com/win/stable/"
}

variable "active_directory_netbios_name" {
  description = "The netbios name of the Active Directory domain, for example `consoto`"
  default     = "tera"
}

variable "domain_group" {
  description = "Active Directory Distinguished Name for the User Group to log into the CAM Management Interface. Default is 'Domain Admins'. (eg, 'CN=CAM Admins,CN=Users,DC=example,DC=com')"
  default     = "Domain Admins"
}

variable "instance_count" {
  description = "Number of Cloud Access Connectors to deploy"
  default     = 1
}

variable "cac_host_name" {
  description = "Name to give the host"
  default     = "vm-cac"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  default     = ""
}

variable "cac_machine_type" {
  description = "Machine type for the Cloud Access Connector"
  default     = "Standard_D2s_v3"
}

variable "disk_size_gb" {
  description = "Disk size (GB) of the Cloud Access Connector"
  default     = "50"
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
