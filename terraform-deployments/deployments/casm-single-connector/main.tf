/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

module "workstation-map" {
  source       = "../../modules/workstation-map"
  workstations = var.workstations
}

module "aadds-network" {
  source = "../../modules/casm/aadds-network-vnet"

  resource_group_name     = azurerm_resource_group.main.name
  locations               = module.workstation-map.virtual-network-locations
 
  prefix                        = var.prefix
  application_id                = var.application_id
  aad_client_secret             = var.aad_client_secret
  main_vnet_name                = "vnet_${azurerm_resource_group.main.location}"
  aadds_vnet_name               = var.aadds_vnet_name
  aadds_vnet_rg                 = var.aadds_vnet_rg
  aadds_domain_name             = var.aadds_domain_name
  ws_subnet_cidr                = [cidrsubnet(local.vnet_cidr, 8, 0)]
  vnet_cidr                     = local.vnet_cidr
  # Debug flag
  create_debug_rdp_access = var.create_debug_rdp_access
}


module "casm" {
  source = "../../modules/casm/casm-vm"
  blob_depends_on = [azurerm_storage_account.storage, azurerm_storage_container.blob]

  casm_subnet_depends_on = module.aadds-network.all-output
  cas_mgr_deployment_sa_file = local.cas_mgr_deployment_sa_file
  cas_mgr_admin_password     = var.cas_mgr_admin_password
  private_container_url      = azurerm_storage_container.private-container.id

  storage_account_name         = azurerm_storage_account.storage.name
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  azurerm_virtual_network_name = module.aadds-network.vnet_name
  network_security_group_ids   = module.aadds-network.network-security-group-ids

  application_id              = var.application_id
  aad_client_secret           = var.aad_client_secret
  ad_service_account_username = var.ad_admin_username
  ad_service_account_password = var.ad_admin_password
  tenant_id                   = var.tenant_id
  key_vault_id                = var.key_vault_id
  ad_pass_secret_name         = var.ad_pass_secret_name
  pcoip_registration_code     = var.pcoip_registration_code
  object_id                   = var.object_id
  key_vault_name              = var.key_vault_name == "" ? "kv-${random_id.string.hex}" : var.key_vault_name
  cas_mgr_subnet_cidr         = [cidrsubnet(local.vnet_cidr, 8, 1)]
  storage_connection_string = azurerm_storage_account.storage.primary_connection_string
  private_container_name    = azurerm_storage_container.private-container.name
  aadds_resource_group      = var.resource_group_name
  cas_mgr_add_repo_script   = "https://dl.teradici.com/yj39yHtgj68Uv2Qf/cas-manager/cfg/setup/bash.rpm.sh"
}


module "cac" {
  source = "../../modules/cac-cas-mgr-aadds"
  cac_subnet_depends_on = [module.aadds-network.all-output, module.casm.subnet]
  cac_count_list = [var.cac_instance_count]
  cac_subnet_cidr = [cidrsubnet(local.vnet_cidr, 8, 2)]
  cas_mgr_url                = "https://${module.casm.internal-ip}"
  cas_mgr_insecure           = true
  cas_mgr_deployment_sa_file = local.cas_mgr_deployment_sa_file

  network_security_group_ids    = module.aadds-network.network-security-group-ids
  azurerm_virtual_network_names = [module.aadds-network.vnet_name]

  prefix                = var.prefix
  domain_name           = var.aadds_domain_name
  domain_controller_ip  = data.azurerm_virtual_network.aadds_vnet.dns_servers[0]
  storage_account_name  = azurerm_storage_account.storage.name
  private_container_url = azurerm_storage_container.private-container.id

  cac_admin_user     = var.cac_admin_username
  cac_admin_password = var.ad_admin_password

  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  locations                   = module.workstation-map.virtual-network-locations
  application_id              = var.application_id
  aad_client_secret           = var.aad_client_secret
  ad_service_account_username = var.ad_admin_username
  ad_service_account_password = var.ad_admin_password
  key_vault_id                = var.key_vault_id
  ad_pass_secret_name         = var.ad_pass_secret_name
  ssl_key                     = var.ssl_key
  ssl_cert                    = var.ssl_cert

  aadds_resource_group      = var.resource_group_name

  storage_connection_string = azurerm_storage_account.storage.primary_connection_string
  private_container_name    = azurerm_storage_container.private-container.name
}

module "aadds-mgmt-vm" {
  source = "../../modules/aadds-mgmt-vm"
  location                     = azurerm_resource_group.main.location

  windows_host_vm_depends_on = [module.aadds-network.subnet-workstation-ids[0]]
  blob_depends_on = [azurerm_storage_account.storage, azurerm_storage_container.blob]
  workstations                 = module.workstation-map.windows-std-workstations
  resource_group_name          = azurerm_resource_group.main.name
  admin_name                   = var.windows_admin_username
  admin_password               = var.ad_admin_password
  pcoip_registration_code      = var.pcoip_registration_code
  domain_name                  = var.aadds_domain_name
  ad_service_account_username  = var.ad_admin_username
  ad_service_account_password  = var.ad_admin_password
  application_id               = var.application_id
  aad_client_secret            = var.aad_client_secret
  key_vault_id                 = var.key_vault_id
  ad_pass_secret_name          = var.ad_pass_secret_name
  storage_account_name         = azurerm_storage_account.storage.name
  workstation_subnet_ids       = module.aadds-network.subnet-workstation-ids
  workstation_subnet_locations = module.aadds-network.subnet-workstation-locations

  enable_workstation_idle_shutdown = var.enable_workstation_idle_shutdown
  minutes_idle_before_shutdown     = var.minutes_idle_before_shutdown
  minutes_cpu_polling_interval     = var.minutes_cpu_polling_interval
}

module "windows-std-vm" {
  source = "../../modules/windows-std-vm"

  windows_host_vm_depends_on = [module.aadds-network.subnet-workstation-ids[0]]
  blob_depends_on = [azurerm_storage_account.storage, azurerm_storage_container.blob]
  workstations                 = module.workstation-map.windows-std-workstations
  resource_group_name          = azurerm_resource_group.main.name
  admin_name                   = var.windows_admin_username
  admin_password               = var.ad_admin_password
  pcoip_registration_code      = var.pcoip_registration_code
  domain_name                  = var.aadds_domain_name
  ad_service_account_username  = var.ad_admin_username
  ad_service_account_password  = var.ad_admin_password
  application_id               = var.application_id
  aad_client_secret            = var.aad_client_secret
  key_vault_id                 = var.key_vault_id
  ad_pass_secret_name          = var.ad_pass_secret_name
  storage_account_name         = azurerm_storage_account.storage.name
  workstation_subnet_ids       = module.aadds-network.subnet-workstation-ids
  workstation_subnet_locations = module.aadds-network.subnet-workstation-locations

  enable_workstation_idle_shutdown = var.enable_workstation_idle_shutdown
  minutes_idle_before_shutdown     = var.minutes_idle_before_shutdown
  minutes_cpu_polling_interval     = var.minutes_cpu_polling_interval
}

module "windows-gfx-vm" {
  source = "../../modules/windows-gfx-vm"

  windows_host_vm_depends_on = [module.aadds-network.subnet-workstation-ids[0]]
  blob_depends_on = [azurerm_storage_account.storage, azurerm_storage_container.blob]
  workstations                 = module.workstation-map.windows-gfx-workstations
  resource_group_name          = azurerm_resource_group.main.name
  admin_name                   = var.windows_admin_username
  admin_password               = var.ad_admin_password
  pcoip_registration_code      = var.pcoip_registration_code
  domain_name                  = var.aadds_domain_name
  ad_service_account_username  = var.ad_admin_username
  ad_service_account_password  = var.ad_admin_password
  application_id               = var.application_id
  aad_client_secret            = var.aad_client_secret
  key_vault_id                 = var.key_vault_id
  ad_pass_secret_name          = var.ad_pass_secret_name
  storage_account_name         = azurerm_storage_account.storage.name
  workstation_subnet_ids       = module.aadds-network.subnet-workstation-ids
  workstation_subnet_locations = module.aadds-network.subnet-workstation-locations

  enable_workstation_idle_shutdown = var.enable_workstation_idle_shutdown
  minutes_idle_before_shutdown     = var.minutes_idle_before_shutdown
  minutes_cpu_polling_interval     = var.minutes_cpu_polling_interval
}

module "centos-std-vm" {
  source = "../../modules/centos-std-vm"

  #centos_std_depends_on = [module.dc-cac-network.subnet-dc-id]

  workstations                 = module.workstation-map.centos-std-workstations
  resource_group_name          = azurerm_resource_group.main.name
  admin_name                   = var.centos_admin_username
  admin_password               = var.ad_admin_password
  pcoip_registration_code      = var.pcoip_registration_code
  domain_name                  = var.aadds_domain_name
  ad_service_account_username  = var.ad_admin_username
  ad_service_account_password  = var.ad_admin_password
  application_id               = var.application_id
  aad_client_secret            = var.aad_client_secret
  key_vault_id                 = var.key_vault_id
  ad_pass_secret_name          = var.ad_pass_secret_name
  domain_controller_ip         = data.azurerm_virtual_network.aadds_vnet.dns_servers[0]
  workstation_subnet_ids       = module.aadds-network.subnet-workstation-ids
  workstation_subnet_locations = module.aadds-network.subnet-workstation-locations
  enable_workstation_idle_shutdown = var.enable_workstation_idle_shutdown
  minutes_idle_before_shutdown     = var.minutes_idle_before_shutdown
  minutes_cpu_polling_interval     = var.minutes_cpu_polling_interval
}

module "centos-gfx-vm" {
  source = "../../modules/centos-gfx-vm"

  #centos_gfx_depends_on = [module.dc-cac-network.subnet-dc-id]

  workstations                 = module.workstation-map.centos-gfx-workstations
  resource_group_name          = azurerm_resource_group.main.name
  admin_name                   = var.centos_admin_username
  admin_password               = var.ad_admin_password
  pcoip_registration_code      = var.pcoip_registration_code
  domain_name                  = var.aadds_domain_name
  ad_service_account_username  = var.ad_admin_username
  ad_service_account_password  = var.ad_admin_password
  application_id               = var.application_id
  aad_client_secret            = var.aad_client_secret
  key_vault_id                 = var.key_vault_id
  ad_pass_secret_name          = var.ad_pass_secret_name
  domain_controller_ip         = data.azurerm_virtual_network.aadds_vnet.dns_servers[0]
  workstation_subnet_ids       = module.aadds-network.subnet-workstation-ids
  workstation_subnet_locations = module.aadds-network.subnet-workstation-locations

  enable_workstation_idle_shutdown = var.enable_workstation_idle_shutdown
  minutes_idle_before_shutdown     = var.minutes_idle_before_shutdown
  minutes_cpu_polling_interval     = var.minutes_cpu_polling_interval
}
