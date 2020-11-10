/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "dc_vm_setup_depends_on" {
  description = "Used to configure dependcies for this module"
  type    = any
  default = null
}

variable "active_directory_domain_users_list_file" {
  description = "The active directory users list CSV file used to populate the directory"
  type        = string
}

# This is only valid if using a key vault
variable "ad_pass_secret_name" {
  description = "The name of the Active Directory secret password"
  type        = string
  default     = ""
}

# This is only valid if using a key vault
variable "key_vault_id" {
  description = "The key vault resource ID"
  type        = string
  default     = ""
}

locals {
  use_secret_or_not    = var.ad_admin_password != "" ? { ad_admin_password = var.ad_admin_password } : { ad_admin_password = tostring(data.azurerm_key_vault_secret.ad-pass[0].value) }
  new_domain_users           = var.active_directory_domain_users_list_file == "" ? 0 : 1
  setup_file                 = "C:/Temp/setup.ps1"
  setup_add_admin_file       = "C:/Temp/add_admin.ps1"
  new_domain_users_file      = "C:/Temp/new_domain_users.ps1"
  domain_users_list_file     = "C:/Temp/domain_users_list.csv"
}
