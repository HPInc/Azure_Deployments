/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "dc_cac_network_depends_on" {
  description = "Value that internal module components can use as a dependency for externally created recources"
  type    = any
  default = null
}

 variable "vnet_name" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
  default     = "vnet"
}

variable "dc_subnet_name" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
  default     = "dc-subnet"
}

variable "workstation_subnet_name" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
  default     = "workstation-subnet"
}

variable "dc_private_ip" {
  description = "Static internal IP address for the Domain Controller"
  default     = "10.0.1.4"
}

variable "dc_subnet_cidr" {
  description = "CIDR for subnet containing the Domain Controller"
  default     = "10.0.1.0/24"
}

variable "allowed_client_cidrs" {
  description = "Open VPC firewall to allow PCoIP connections from these IP Addresses or CIDR ranges. e.g. 'a.b.c.d', 'e.f.g.0/24'"
  default     = "0.0.0.0/0"
}

variable "create_debug_public_ips" {
  description = "Should the configuration create public ip addresses for debug purposes"
  type        = bool
  default     = false
}

variable "create_debug_rdp_access" {
  description = "Should the configuration create rdp access to the virtual machines"
  type        = bool
  default     = false
}
