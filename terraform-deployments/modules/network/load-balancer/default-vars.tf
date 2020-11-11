/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "load_balancer_depends_on" {
  description = "Value that internal module components can use as a dependency for externally created recources"
  type    = any
  default = null
}

 variable "prefix" {
  description = "Prefix used for the name of the load balancer"
  type        = string
  default     = "cac"
 }

variable "probe_name" {
  description = "The name of the load balancer probe profile"
  type        = string
  default     = "pcoip-probe"
}

variable "probe_port" {
  description = "The Vm port used for polling"
  type        = string
  default     = "443"
}

variable "probe_protocol" {
  description = "The Vm port used for polling"
  type        = string
  default     = "https"
}

variable "probe_path" {
  description = "The VM polling URL"
  type        = string
  default     = "/pcoip-broker/xml"
}

variable "create_debug_ssh_access" {
  description = "Debug flag to open up ssh access"
  type        = bool
  default     = false
}