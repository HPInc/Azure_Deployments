/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "aad_client_secret" {
  description = "The client secret of your app registration in AAD"
  type        = string
}

variable "ad_pass_secret_name" {
  description = "Name of ad admin password"
}

variable "ad_service_account_username" {
  description = "Active Directory Service Account username"
  type        = string
}

variable "ad_service_account_password" {
  description = "Active Directory Service Account password"
  type        = string
}

variable "application_id" {
  description = "The application (client) ID of your app registration in AAD"
  type        = string
}

variable "azurerm_virtual_network_names" {
  description = "List of virtual network names"
  type        = list(string)
}

variable "storage_account_name" {
  description = "Name of the storage account name."
}

variable "private_container_url" {
  description = "URL of the private container."
}

variable "storage_connection_string" {
  description = "Connection string used to create a SAS token."
}

variable "private_container_name" {
  description = "Name of container which stores .json key file."
}

variable "cac_admin_user" {
  description = "Username of the Cloud Access Connector Administrator"
  type        = string
}

variable "cac_admin_password" {
  description = "Password for the Administrator of the Cloud Access Connector VM"
  type        = string
}

variable "cac_count_list" {
  description = "Number of Cloud Access Connector instances to deploy in each zone"
  type        = list(number)
}

variable "cac_subnet_name" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
  default     = "cac-subnet"
}

variable "cas_mgr_deployment_sa_file" {
  description = "Filename of CAS Manager Deployment Service Account JSON key in bucket"
  type        = string
}

variable "cas_mgr_insecure" {
  description = "Allow unverified TLS access to CAS Manager"
  type        = bool
  default     = false
}

variable "cas_mgr_url" {
  description = "CAS Manager URL"
  default     = "https://cas.teradici.com"
}

variable "disk_size_gb" {
  description = "Disk size (GB) of the Cloud Access Connector"
  default     = "50"
}

variable "domain_controller_ip" {
  description = "Internal IP of the Domain Controller"
  type        = string
}

variable "domain_name" {
  description = "Name of the domain to join"
  type        = string
}

variable "key_vault_id" {
  description = "Key vault ID for ad admin password"
}

variable "resource_group_name" {
  description = "Name of the resource group"
}

variable "location" {
  description = "Location of CAC virtual machine"
}

variable "locations" {
  description = "The Azure Regions in which resources will be created"
  type        = list(string)
}

variable "machine_type" {
  description = "Machine type for the Cloud Access Connector"
  default     = "Standard_B2ms"
}

variable "network_security_group_ids" {
  description = "List of network security group ids"
  type        = list(string)
}

variable "prefix" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
}

variable "tls_key" {
  description = "TLS private key for the Connector"
  default     = ""
}

variable "tls_cert" {
  description = "TLS certificate for the Connector"
  default     = ""
}

variable "tenant_id" {
  description = "The directory (tenant) ID of your app registration in AAD"
  type        = string
}

variable "aadds_resource_group" {
  description = "Name of the resource group the AADDS belongs in"
  default     = ""
}

variable "cac_depends_on" {
  description = "Value that internal module components can use as a dependency for externally created recources"
  type        = any
  default     = null
}

variable "is_private" {
  description = "Determines whether or not the CACs will be created with public IPs attached"
  type        = bool
  default     = false
}

variable "blob_depends_on" {
  description = "Storage account that the storage blob requires as a dependency"
  type        = any
  default     = null
}

variable "cac_nat_depends_on" {
  type        = any
  default     = null
}

variable "cac_subnet_depends_on" {
  description = "Modules that the subnet requires as a dependency"
  type        = any
  default     = null
}


variable "cas_mgr_internal_ip" {
  description = "Internal IP of the CAS manager"
  type        = string
  default     = ""
}

variable "cas_mgr_public_ip" {
  description = "Public IP of the CAS manager"
  type        = string
  default     = ""
}

variable "cas_mgr_cidr" {
  description = "Internal CIDR of the CAS manager"
  type        = string
  default     = ""
}

variable "cas_mgr_public_ip_id" {
  description = "ID of the Public IP of the CAS manager"
  type        = string
  default     = ""
}

variable "dc_subnet_cidr" {
  description = "Internal CIDR of the domain controller"
  type        = string
  default     = ""
}

variable "dc_public_ip_id" {
  description = "ID of the Public IP of the CAS domain controller"
  type        = string
  default     = ""
}

variable "cac_public" {
  description = "Public IPs of the Firewall which NAT to the internal CAC IPs"
  type        = any
}

variable "lb_id" {
  description = "ID of Load Balancer."
  type        = string
  default = ""
}

variable "probe_id" {
  description = "ID of Load Balancer health probe."
  type        = string
  default = ""
}

variable "computers_dn" {
  description = "Base DN to search for computers within Active Directory."
  type        = string
}

variable "users_dn" {
  description = "Base DN to search for users within Active Directory."
  type        = string
}