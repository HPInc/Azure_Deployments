/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "prefix" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
}

variable "locations" {
  description = "The Azure Regions in which resources will be created. The first locaion in the list is deemed to be the the main region and the next N are peers of the main"
  type        = list(string)
}

variable "resource_group_name" {
  description = "The name of the resource group"
}

variable "aad_client_secret" {
  description = "The client secret of your app registration in AAD"
  type        = string
}

variable "application_id" {
  description = "The application (client) ID of your app registration in AAD"
  type        = string
}

variable "aadds_vnet_name" {
  description = "Name of VNET that the AADDS belongs in"
  type        = string
}

variable "aadds_vnet_rg" {
  description = "Name of resouce group that the AADDS belongs in"
  type        = string
}

variable "aadds_domain_name" {
  description = "Name of the AADDS domain"
  type        = string
}

variable "vnet_cidr" {
  type    = string
}

variable "main_vnet_name" {
  type = string
}