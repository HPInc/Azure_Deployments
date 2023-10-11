/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "resource_group_name" {
  description = "Name of the resource group"
}

variable "cac_configuration" {
  description = "List of cac vrtual machines create"
  type = list(object({
    location  = string
    cac_token = string
  }))
}

variable "domain_name" {
  description = "Name of the domain to join"
  type        = string
}

variable "domain_controller_ip" {
  description = "Internal IP of the Domain Controller"
  type        = string
}

variable "ad_service_account_username" {
  description = "Active Directory Service Account username"
  type        = string
}

variable "ad_service_account_password" {
  description = "Active Directory Service Account password"
  type        = string
}

variable "nic_ids" {
  description = "List of network interface card ids for the cloud access connector"
  type        = list(string)
}

variable "cac_admin_user" {
  description = "Username of the Cloud Access Connector Administrator"
  type        = string
}

variable "cac_admin_password" {
  description = "Password for the Administrator of the Cloud Access Connector VM"
  type        = string
}

variable "dns_zone_id" {
  description = "Default DNS Zone ID"
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

variable "key_vault_id" {
  description = "Key vault ID for ad admin password"
}

variable "ad_pass_secret_name" {
  description = "Name of ad admin password"
}
