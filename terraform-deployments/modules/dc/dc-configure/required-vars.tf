/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "domain_controller_virtual_machine_name" {
  description = "The domain controller vm name"
  type        = string
}

variable "resource_group_name" {
  description = "The resource group the domain controller vm resides in"
  type        = string
}

variable "aad_client_secret" {
  description = "The client secret of your app registration in AAD"
  type        = string
}

variable "application_id" {
  description = "The application (client) ID of your app registration in AAD"
  type        = string
}
