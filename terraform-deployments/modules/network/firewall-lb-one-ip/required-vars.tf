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

variable "location" {
  description = "Location of CAC virtual machine"
}

variable "resource_group_name" {
  description = "Name of the resource group that the route table will associate with."
  type = string
}

variable "virtual_network_name" {
  description = "Name of virtual network"
}

variable "fw_subnet_cidr" {
  description = "CIDR for the subnet the firewall will be created in."
  default     = ["10.0.8.0/24"]
}

variable "instance_count" {
  description = "Number of Cloud Access Connector instances to deploy in each zone"
}

