/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

 variable "locations" {
  description = "The Azure Regions in which resources will be created. The first locaion in the list is deemed to be the the main region and the next N are peers of the main"
  type        = list(string)
}

variable "resource_group_name" {
  description = "Name of the resource group that the route table will associate with."
  type = string
}

variable "cac_subnet_ids" {
  description = "List of cac subnet ids the route table will associate with"
  type        = list(string)
}

variable "ws_subnet_ids" {
  description = "List of workstation subnet ids the route table will associate with"
  type        = list(string)
}

variable "dc_subnet_id" {
  description = "Domain controller subnet id the route table will associate with"
  type        = string
}

variable "cas_subnet_id" {
  description = "CAS Manager subnet id the route table will associate with"
  type        = string
}


variable "fw_public_ip"{
  description = "Public IP of the firewall for internet routing"
  type        = string
}

variable "fw_private_ip"{
  description = "Private IP of the firewall for internet routing"
  type        = string
}

variable "route_table_depends_on" {
  type = any
}