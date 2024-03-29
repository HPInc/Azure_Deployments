/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "blob_depends_on" {
  description = "Storage account that the storage blob requires as a dependency"
  type        = any
  default     = null
}

variable "windows_host_vm_depends_on" {
  description = "Value that internal module components can use as a dependency for externally created recources"
  type        = any
  default     = null
}

variable "enable_workstation_idle_shutdown" {
  description = "Enable Cloud Access Manager auto idle shutdown for Workstations"
  default     = true
}

variable "minutes_idle_before_shutdown" {
  description = "Minimum idle time for Workstations before auto idle shutdown, must be between 5 and 10000"
  default     = 240
}

variable "minutes_cpu_polling_interval" {
  description = "Polling interval for checking CPU utilization to determine if machine is idle, must be between 1 and 60"
  default     = 15
}

variable "is_aadds" {
  description = "Value that determines whether or not the provisioning script used will be for AADDS (Azure Active Directory Domain Services) domains"
  default = false
}

variable "tenant_id" {
  description = "The directory (tenant) ID of your app registration in AAD"
  type        = string
  default     = ""
}

variable "managed_identity_id" {
  description = "The id of managed identity"
  type        = string
  default     = ""
}