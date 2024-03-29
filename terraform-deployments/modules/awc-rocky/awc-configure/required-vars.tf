/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "cac_configuration" {
  description = "List of cac vrtual machines create"
  type = list(object({
    location  = string
    cac_token = string
  }))
}

variable "ad_service_account_username" {
  description = "Active Directory Service Account username"
  type        = string
}

variable "ad_service_account_password" {
  description = "Active Directory Service Account password"
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

variable "cac_admin_user" {
  description = "Username of the Cloud Access Connector Administrator"
  type        = string
}

variable "cac_admin_password" {
  description = "Password for the Administrator of the Cloud Access Connector VM"
  type        = string
}

variable "cac_ips" {
  description = "IP addresses of the CAC VMs"
  type        = list(string)
}

variable "aad_client_secret" {
  description = "The client secret of your app registration in AAD"
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

variable "cac_vm_ids" {
  description = "The id of the cac vm"
  type        = list(string)
}

variable "key_vault_id" {
  description = "Key vault ID for ad admin password"
}

variable "ad_pass_secret_name" {
  description = "Name of ad admin password"
}

variable "computers_dn" {
  description = "Base DN to search for computers within Active Directory."
  type        = string
}

variable "users_dn" {
  description = "Base DN to search for users within Active Directory."
  type        = string
}