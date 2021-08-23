/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "cac_network_depends_on" {
  description = "Value that internal module components can use as a dependency for externally created recources"
  type    = any
  default = null
}

variable "cac_subnet_name" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
  default     = "cac-subnet"
}