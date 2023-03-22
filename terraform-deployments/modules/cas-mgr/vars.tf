/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "aad_client_secret" {
  description = "The client secret of your app registration in AAD"
  type        = string
  default     = ""
}

variable "application_id" {
  description = "The application (client) ID of your app registration in AAD"
  type        = string
  default     = ""
}

variable "private_container_url" {
  description = "URL of the private container storage."
}

variable "location" {
  description = "Location of CAS Manager virtual machine"
}

variable "prefix" {
  description = "Prefix to add to name of new resources"
  default     = ""
}

variable "pcoip_registration_code" {
  description = "PCoIP Registration code"
  type        = string
}

variable "cas_mgr_deployment_sa_file" {
  description = "Filename of CAS Manager Deployment Service Account JSON key in bucket"
  type        = string
}

variable "cas_mgr_subnet_depends_on" {
  description = "Subnet dependencies"
  type        = any
  default = null
}

variable "machine_type" {
  description = "Instance type for the CAS Manager (min 8 GB RAM, 4 vCPUs)"
  # default   = "Standard_F4s_v2"
  default = ["Standard_D2s_v3"]
}

variable "disk_size_gb" {
  description = "Disk size (GB) of the CAS Manager (min 60 GB)"
  default     = "60"
}

variable "host_name" {
  description = "Name to give the host"
  default     = "cas-mgr-vm"
}

variable "cas_mgr_admin_password" {
  description = "Password for the Administrator of CAS Manager"
  type        = string
}

variable "cas_mgr_add_repo_script" {
  description = "Location of script to add repo for CAS Manager"
  default     = "https://dl.teradici.com/yj39yHtgj68Uv2Qf/cas-manager/cfg/setup/bash.rpm.sh"
}

variable "cas_mgr_subnet_cidr" {
  description = "CIDR for subnet containing the CAS Manager"
  default     = ["10.0.2.0/24"]
}

variable "cas_mgr_subnet_name" {
  description = "Number of PCoIP session licenses to activate"
  default     = "subnet-cas-mgr"
}

variable "storage_account_name" {
  description = "Name of storage account that contains scripts"
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

variable "resource_group_name" {
  description = "The name of the resource group"
  default     = ""
}

variable "ad_service_account_password" {
  description = "Active Directory Service Account password"
  type        = string
}

variable "ad_service_account_username" {
  description = "Active Directory Service Account username"
  type        = string
}

variable "azurerm_virtual_network_name" {
  description = "Name of the virtual network"
}

variable "network_security_group_ids" {
  description = "List of network security groups"
}

variable "storage_connection_string" {
  description = "Connection string used to create a SAS token."
}

variable "private_container_name" {
  description = "Name of container which stores .json key file."
}

variable "blob_depends_on" {
  description = "Storage account that the storage blob requires as a dependency"
  type        = any
  default     =  null
}

variable "tag_name" {
  description = "Name of the artifact to be tagged with the resulting format value = tag_prefix + tag_value + tag_suffix"
  type        = string
  default     = "Type"
}

variable "tag_prefix" {
  description = "Name of the prefix formatted tag value"
  type        = string
  default     = "AW"
}

variable "tag_value" {
  description = "Name of the prefix formatted tag value"
  type        = string
  default     = "cas-mgr-single-connector"
}

variable "tag_suffix" {
  description = "Name of the prefix formatted tag value"
  type        = string
  default     = "VM"
}
