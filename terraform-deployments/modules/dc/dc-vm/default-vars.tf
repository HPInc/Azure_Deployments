/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "dc_vm_depends_on" {
  description = "Used to configure dependencies for this module"
  type        = any
  default     = null
}

variable "dc_machine_type" {
  description = "Machine type for Domain Controller"
  default     = "Standard_F2"
}

variable "key_vault_id" {
  description = "The key vault resource ID"
  type        = string
  default     = ""
}

variable "ad_pass_secret_name" {
  description = "The name of the Active Directory secret password"
  type        = string
  default     = ""
}

locals {
  ad_admin_password    = var.key_vault_id == "" ? var.ad_admin_password : tostring(data.azurerm_key_vault_secret.ad-pass[0].value)
  prefix               = var.prefix != "" ? "${var.prefix}-" : ""
  virtual_machine_name = "${local.prefix}dc-vm"
  virtual_machine_fqdn = join(".", [local.virtual_machine_name, var.active_directory_domain_name])
  auto_logon_data      = "<AutoLogon><Password><Value>${local.ad_admin_password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.ad_admin_username}</Username></AutoLogon>"
  first_logon_data     = file("${path.module}/files/FirstLogonCommands.xml")
  custom_data_params   = "Param($RemoteHostName = \"${local.virtual_machine_fqdn}\", $ComputerName = \"${local.virtual_machine_name}\")"
  custom_data          = base64encode(join(" ", [local.custom_data_params, file("${path.module}/files/winrm.ps1")]))
}
