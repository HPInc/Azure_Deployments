/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "traffic_manager_depends_on" {
  description = "Value that internal module components can use as a dependency for externally created recources"
  type    = any
  default = null
}

 variable "resource_name" {
  description = "The name used when creating the traffic manager recource"
  type        = string
  default     = "traffic-manager"
}

variable "profile_port" {
  description = "The Vm port used for polling"
  type        = string
  default     = "443"
}

variable "profile_protocol" {
  description = "The Vm port used for polling"
  type        = string
  default     = "https"
}

variable "profile_path" {
  description = "The VM polling URL"
  type        = string
  default     = "/pcoip-broker/xml"
}