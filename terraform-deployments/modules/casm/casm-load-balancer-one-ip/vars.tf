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