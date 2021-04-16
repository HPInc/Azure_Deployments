/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "cac_depends_on" {
  description = "Value that internal module components can use as a dependency for externally created recources"
  type        = any
  default     = null
}

variable "prefix" {
  description = "Prefix to add to name of new resources"
  default     = ""
}

variable "location" {
  description = "Zone to deploy the Cloud Access Connector"
  default     = "centralus"
}

variable "machine_type" {
  description = "Machine type for the Cloud Access Connector"
  default     = "Standard_B2ms"
}

variable "disk_size_gb" {
  description = "Disk size (GB) of the Cloud Access Connector"
  default     = "50"
}

