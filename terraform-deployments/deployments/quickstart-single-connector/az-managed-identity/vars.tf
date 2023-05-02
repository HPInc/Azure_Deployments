/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "location" {
  description = "Location of the deployment"
  default     = "westus2"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  default     = ""
}

variable "managed_identity_name" {
  description = "Name of the Azure managed identity"
  default     = ""
}
