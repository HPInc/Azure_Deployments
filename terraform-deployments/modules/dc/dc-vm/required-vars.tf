/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
}

variable "resource_group_name" {
  description = "The name of the resource group"
}

variable "ad_admin_username" {
  description = "Username for the Domain Administrator user"
}

variable "ad_admin_password" {
  description = "Password for the Adminstrator user"
}

variable "nic_id" {
  description = "Network Interafce Card Id"
}

variable "active_directory_domain_name" {
  description = "the domain name for Active Directory, for example `consoto.local`"
}

variable "aad_client_secret" {
  description = "The client secret of your app registration in AAD"
  type        = string
}

variable "application_id" {
  description = "The application (client) ID of your app registration in AAD"
  type        = string
}
