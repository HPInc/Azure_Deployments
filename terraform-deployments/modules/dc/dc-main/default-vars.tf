/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "vnet_name" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
  default     = "virtual-network"
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

variable "dc_machine_type" {
  description = "Machine type for Domain Controller"
  default     = "Standard_F4"
}

variable "domain_users_list" {
  description = "Active Directory users to create, in CSV format"
  type        = string
  default     = ""
}
