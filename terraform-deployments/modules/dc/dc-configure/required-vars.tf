/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "domain_controller_virtual_machine_name" {
  description = "The domain controller vm name"
  type        = string
}

variable "resource_group_name" {
  description = "The resouce group the domain controller vm resides in"
  type        = string
}
