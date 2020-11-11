/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "dns_name" {
  description = "The dns name of the traffic manager"
  type        = string
}

variable "managed_endpoints" {
  description = "A list of endpoint ip addresses managed by the traffic manager"
  type        = list(string)
}

variable "managed_endpoint_names" {
  description = "A list of endpoint VM names managed by the traffic manager"
  type        = list(string)
}