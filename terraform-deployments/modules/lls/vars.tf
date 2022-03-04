/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "resource_group_name" {
  description = "Basename of the Resource Group to deploy the LLS server machine."
  type        = string
}

variable "ad_service_account_username" {
  description = "Name for the Administrator of the LLS server machine"
  type        = string
}

variable "ad_service_account_password" {
  description = "Password for the Administrator of the LLS server machine"
  type        = string
}

variable "machine_type" {
  description = "Azure virtual machine size."
  default     = "Standard_B2ms"
}

variable "application_id" {
  description = "The application (client) ID of your app registration in AAD"
  type        = string
}

variable "aad_client_secret" {
  description = "The client secret of your app registration in AAD"
  type        = string
}

variable "instance_count" {
  description = "Number of PCoIP License Server to deploy"
  default     = 1
}

variable "disk_size_gb" {
  description = "Disk size (GB) of the PCoIP License Server"
  default     = "30"
}

variable "host_name" {
  description = "Name to give the host"
  default     = "lls-vm"
}

variable "teradici_download_token" {
  description = "Token used to download from Teradici"
  default     = "yj39yHtgj68Uv2Qf"
}

variable "lls_admin_password" {
  description = "Administrative password for the Teradici License Server"
  default     = ""
}

variable "lls_activation_code" {
  description = "Activation Code for PCoIP session licenses"
  default     = ""
}

variable "lls_license_count" {
  description = "Number of PCoIP session licenses to activate"
  default     = 0
}

variable "lls_subnet_name" {
  description = "Number of PCoIP session licenses to activate"
  default     = "subnet-lls"
}

variable "azurerm_virtual_network_name" {
  description = "Name of the virtual network"
}

variable "location" {
  description = "Location of the Local License Server"
}

variable "key_vault_id" {
  description = "Key vault ID for ad admin password"
}

variable "ad_pass_secret_name" {
  description = "Name of ad admin password"
}

variable "tenant_id" {
  description = "The directory (tenant) ID of your app registration in AAD"
  type        = string
  default     = ""
}
