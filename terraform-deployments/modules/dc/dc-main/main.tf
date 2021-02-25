/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  ad_admin_password = var.key_vault_id == "" ? var.ad_admin_password : tostring(data.azurerm_key_vault_secret.ad-pass[0].value)
}

data "azurerm_key_vault_secret" "ad-pass" {
  count        = var.key_vault_id != "" ? 1 : 0
  name         = var.ad_pass_secret_name
  key_vault_id = var.key_vault_id
}

module "active-directory-domain-network" {
  source = "../dc-network"

  dc_network_depends_on = [
    var.dc_main_depends_on]

  resource_group_name = var.resource_group_name
  location            = var.location

  prefix                        = var.prefix
  vnet_name                     = var.vnet_name
  dc_subnet_name                = var.dc_subnet_name
  workstation_subnet_name       = var.workstation_subnet_name

}

module "active-directory-domain-vm" {
  source = "../dc-vm"

  dc_vm_depends_on = [
    var.dc_main_depends_on,
    module.active-directory-domain-network.all-output
  ]

  resource_group_name = var.resource_group_name
  location            = var.location

  active_directory_domain_name  = "${var.active_directory_netbios_name}.dns.internal"
  ad_admin_username             = var.ad_admin_username
  ad_admin_password             = local.ad_admin_password
  dc_machine_type               = var.dc_machine_type
  nic_id                        = module.active-directory-domain-network.network-interface-id
  prefix                        = var.prefix
}

module "active-directory-domain-service" {
  source = "../dc-service"

  dc_vm_setup_depends_on = [
    var.dc_main_depends_on,
    module.active-directory-domain-network.all-output,
    module.active-directory-domain-vm.domain-controller-name,
    module.active-directory-domain-vm.domain-controller-id
  ]

  domain_controller_virtual_machine_name = module.active-directory-domain-vm.domain-controller-name
  domain_controller_virtual_machine_id = module.active-directory-domain-vm.domain-controller-id
  domain_controller_virtual_machine_public_ip = module.active-directory-domain-network.public-ip
  active_directory_domain_users_list_file = var.ad_domain_users_list_file

  active_directory_domain_name  = "${var.active_directory_netbios_name}.dns.internal"
  ad_admin_username             = var.ad_admin_username
  ad_admin_password             = local.ad_admin_password
  ad_pass_secret_name           = var.ad_pass_secret_name
  key_vault_id                  = var.key_vault_id
  application_id                = var.application_id
  aad_client_secret             = var.aad_client_secret
  tenant_id                     = var.tenant_id
  safe_admin_pass_secret_id     = var.safe_admin_pass_secret_id
  safe_mode_admin_password      = var.safe_mode_admin_password
}


module "active-directory-domain-configure" {
  source = "../dc-configure"

  dc_configure_depends_on = [
    var.dc_main_depends_on,
    module.active-directory-domain-network.all-output,
    module.active-directory-domain-service.uploaded-scripts,
    module.active-directory-domain-service.uploaded-domain-users-list-count
  ]

  resource_group_name                    = var.resource_group_name

  domain_controller_virtual_machine_name = module.active-directory-domain-vm.domain-controller-name

  dc_configure_file_path                 = pathexpand(var.az_cli_script_path)
}
