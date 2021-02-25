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

variable "application_name" {
  description = "Name of the Azure application"
}

variable "resource_group_name" {
  description = "Name of the Azure application"
}

variable "object_id" {
  description = "Name of the Azure application"
}

variable "app_object_id" {
  description = "Name of the Azure application"
}

variable "ad_admin_password" {
  description = "Password for the Adminstrator user"
}

variable "safe_mode_admin_password" {
  description = "Safe Mode Admin Password (Directory Service Restore Mode - DSRM)"
  type        = string
}

variable "cac_token" {
  description = "Token used to install cloud access connector."
}

variable "pcoip_registration_code" {
  description = "PCoIP Registration code"
  type        = string
}
