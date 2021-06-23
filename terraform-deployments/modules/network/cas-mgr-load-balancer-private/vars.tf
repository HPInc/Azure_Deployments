/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "location" {
  description = "The Azure regions in which resources will be created."
}

variable "instance_count" {
  description = "Number of cac instances that will be configured."
}

variable "resource_group_name" {
  description = "The name of the resource group"
}

variable "cac_network_interface_ids" {
  description = "List of cac network interface ids the load balancer will associate with"
  type        = list(string)
}

variable "cac_subnet_ids" {
  description = "List of cac subnet ids the load balancer will associate with"
  type        = string
}

variable "cac_fw_name" {
  description = "Name of the firewall associated with the Vnet"
  type        = string
}

variable "cac_fw_frontend" {
  description = "Frontend public firewall IP that will NAT to the private load balancer"
  type        = string
}
