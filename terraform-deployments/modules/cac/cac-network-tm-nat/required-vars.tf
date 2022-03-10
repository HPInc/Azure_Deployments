/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "resource_group_name" {
  description = "Name of the resource group"
}

variable "prefix" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
}

variable "locations" {
  description = "The Azure Regions in which resources will be created"
  type        = list(string)
}

variable "cac_configuration" {
  description = "List of cac vrtual machines create"
  type = any
}

variable "azurerm_virtual_network_names" {
  description = "List of virtual network names"
  type        = list(string)
}

variable "network_security_group_ids" {
  description = "The network security group ids"
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

variable "vnet_num" {
  type = any
}