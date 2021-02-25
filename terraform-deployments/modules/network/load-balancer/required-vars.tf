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
  description = "The name of the resource group"
}

variable "cac_configuration" {
  description = "List of cac vrtual machines create"
  type        = list(object({
      location         = string
      cac_token        = string
    }))
}

variable "cac_network_interface_ids" {
  description = "List of cac network interface ids the load balancer will associate with"
  type        = list(string)
}

variable "cac_network_interface_primary_config_name" {
  description = "List of cac network interface config names the load balancer will associate with"
  type        = list(string)
}