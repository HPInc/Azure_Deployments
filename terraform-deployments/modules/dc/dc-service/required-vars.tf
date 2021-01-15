/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "domain_controller_virtual_machine_id" {
  description = "The domain controller vm id"
  type        = string
}

variable "domain_controller_virtual_machine_public_ip" {
  description = "The domain controller vm public ip address"
  type        = string
}

variable "domain_controller_virtual_machine_name" {
  description = "The domain controller vm name"
  type        = string
}

variable "ad_admin_password" {
  description = "Password for the Adminstrator user"
}

variable "ad_admin_username" {
  description = "Username for the Domain Administrator user"
}

variable "active_directory_domain_name" {
  description = "the domain name for Active Directory, for example `consoto.local`"
}

variable "safe_mode_admin_password" {
  description = "Safe Mode Admin Password (Directory Service Restore Mode - DSRM)"
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
