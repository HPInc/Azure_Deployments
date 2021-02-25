/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

data "azurerm_key_vault_secret" "ad-pass" {
  count        = var.key_vault_id != "" ? 1 : 0
  name         = var.ad_pass_secret_name
  key_vault_id = var.key_vault_id
}

data "template_file" "setup-script" {
  template = file("${path.module}/files/setup.ps1")

  vars = {
    account_name             = var.ad_admin_username
    domain_name              = var.active_directory_domain_name
    safe_mode_admin_password = var.safe_mode_admin_password
    application_id           = var.application_id
    aad_client_secret        = var.aad_client_secret
    tenant_id                = var.tenant_id
    virtual_machine_name     = var.domain_controller_virtual_machine_name
  }
}

data "template_file" "setup-add-admins-script" {
  template = file("${path.module}/files/add_admin.ps1")

  vars = {
    account_name = var.ad_admin_username
  }
}

data "template_file" "new-domain-users-script" {
  template = file("${path.module}/files/new_domain_users.ps1")

  vars = {
    domain_name = var.active_directory_domain_name
    csv_file    = local.domain_users_list_file
  }
}
