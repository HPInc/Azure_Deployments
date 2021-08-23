/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  cac_location_list = [for k,v in var.cac_configuration : k]
  cac_count_list = [for k,v in var.cac_configuration : length(v)]
  cac_configuration_list = [for k,v in var.cac_configuration : v]
}

module "workstation-map" {
  source       = "../../modules/workstation-map"
  workstations = var.workstations
}

module "load-balancer" {
  source = "../../modules/network/load-balancer-lb-nat"
  load_balancer_depends_on = [module.dc-cac-network.subnet-dc-id, module.active-directory-domain-vm.dc-machine-type]
  
  instance_count            = local.cac_count_list[0]
  prefix                    = var.prefix
  resource_group_name       = azurerm_resource_group.main.name
  location                  = local.cac_location_list[0]
}

module "load-balancer-extra" {
  count = length(local.cac_count_list) - 1
  source = "../../modules/network/cas-mgr-load-balancer-tf"
  load_balancer_depends_on = [module.dc-cac-network.subnet-dc-id, module.active-directory-domain-vm.dc-machine-type]
  
  instance_count            = local.cac_count_list[count.index + 1]
  prefix                    = var.prefix
  resource_group_name       = azurerm_resource_group.main.name
  location                  = local.cac_location_list[count.index + 1]
}

module "cac-network" {
  source = "../../modules/cac/cac-network-tm-nat"
  count = length(local.cac_location_list)
  
  prefix                        = var.prefix
  resource_group_name           = azurerm_resource_group.main.name
  locations                     = [local.cac_location_list[count.index]]
  cac_configuration             = local.cac_configuration_list[count.index]
  network_security_group_ids    = [concat(module.dc-cac-network.network-security-group-ids, module.dc-cac-network-extra.*.network-security-group-ids[0])[count.index]]
  azurerm_virtual_network_names = [concat(module.dc-cac-network.virtual-network-names, module.dc-cac-network-extra.virtual-network-names)[count.index]]
  application_id                = var.application_id
  aad_client_secret             = var.aad_client_secret
  vnet_num                      = count.index
}

module "cac-vm" {
  source = "../../modules/cac/cac-vm-tm-nat"
  count = length(local.cac_location_list)
  # Module is dependent on the configuration of the domain controller
  cac_depends_on = [
    module.dc-cac-network.all-output,
    module.active-directory-domain-configure.service-configured
  ]

  resource_group_name         = azurerm_resource_group.main.name
  location                    = local.cac_location_list[count.index]
  cac_configuration           = local.cac_configuration_list[count.index]
  prefix                      = var.prefix
  domain_name                 = "${var.active_directory_netbios_name}.dns.internal"
  domain_controller_ip        = module.dc-cac-network.dc-private-ip
  ad_service_account_username = var.ad_admin_username
  ad_service_account_password = var.ad_admin_password
  nic_ids                     = module.cac-network[count.index].cac-network-interface-ids
  machine_type                = var.cac_machine_type
  cac_admin_user              = var.cac_admin_username
  cac_admin_password          = var.ad_admin_password
  dns_zone_id                 = module.dc-cac-network.private-dns-zone-id
  application_id              = var.application_id
  aad_client_secret           = var.aad_client_secret
  tenant_id                   = var.tenant_id
  key_vault_id                = var.key_vault_id
  ad_pass_secret_name         = var.ad_pass_secret_name
  lb_id = length(module.load-balancer-extra.*.load-balancer-ids) == 0 ? module.load-balancer.load-balancer-ids[0] : concat(module.load-balancer.load-balancer-ids, module.load-balancer-extra.*.load-balancer-ids[0])[count.index]
  probe_id = length(module.load-balancer-extra.*.load-balancer-ids) == 0 ? module.load-balancer.probe-id : concat([module.load-balancer], module.load-balancer-extra)[count.index].probe-id
}

module "cac-configuration" {
  source = "../../modules/cac/cac-configure-tm-nat"
  count = length(local.cac_location_list)
  cac_configure_depends_on = [
    module.active-directory-domain-configure.service-configured,
    module.cac-vm.*.cac-vm-ids,
    module.cac-vm.*.cac-ssh,
    module.cac-vm.*.cac-outbound
  ]

  cac_configuration           = local.cac_configuration_list[count.index]
  domain_name                 = "${var.active_directory_netbios_name}.dns.internal"
  domain_controller_ip        = module.dc-cac-network.dc-private-ip
  ad_service_account_username = var.ad_admin_username
  ad_service_account_password = var.ad_admin_password
  cac_admin_user              = var.cac_admin_username
  cac_admin_password          = var.ad_admin_password
  ssl_key                     = var.ssl_key
  ssl_cert                    = var.ssl_cert
  cac_ips                     = length(module.load-balancer-extra.*.load-balancer-ids) == 0 ? module.load-balancer.cac_public.*.ip_address : concat([module.load-balancer], module.load-balancer-extra)[count.index].cac-public.*.ip_address
  cac_vm_ids                  = module.cac-vm[count.index].cac-vm-ids
  application_id              = var.application_id
  aad_client_secret           = var.aad_client_secret
  key_vault_id                = var.key_vault_id
  ad_pass_secret_name         = var.ad_pass_secret_name
  tenant_id                   = var.tenant_id
}

module "traffic-manager" {
  source = "../../modules/network/traffic-manager"

  traffic_manager_depends_on = [
    module.dc-cac-network.all-output,
    module.load-balancer.public-ip
  ]

  resource_group_name    = azurerm_resource_group.main.name
  managed_endpoints      = [module.load-balancer.public-ip]
  managed_endpoint_names = ["lb-https"]
  dns_name               = var.traffic_manager_dns_name
}


module "dc-cac-network" {
  source = "../../modules/network/dc-cac-lb-nat-main"
  resource_group_name     = azurerm_resource_group.main.name
  locations               = [local.cac_location_list[0]]
  vnet_peer_to_peer_links = module.workstation-map.virtual-network-peer-to-peer-links
  dc_nat_depends_on       = [module.load-balancer.probe-id]

  prefix                        = var.prefix
  application_id                = var.application_id
  aad_client_secret             = var.aad_client_secret
  active_directory_netbios_name = var.active_directory_netbios_name
  create_debug_rdp_access       = var.create_debug_rdp_access
  lb_id                         = module.load-balancer.load-balancer-ids[0]
  dc_ip                         = module.load-balancer.dc-public
}

module "dc-cac-network-extra" {
  source = "../../modules/network/dc-cac-tf-nat"
  resource_group_name     = azurerm_resource_group.main.name
  locations               = slice(local.cac_location_list,1,length(local.cac_location_list))
  vnet_peer_to_peer_links = module.workstation-map.virtual-network-peer-to-peer-links
  dc_nat_depends_on       = [module.load-balancer-extra.*.probe-id]

  prefix                        = var.prefix
  application_id                = var.application_id
  aad_client_secret             = var.aad_client_secret
  active_directory_netbios_name = var.active_directory_netbios_name
  create_debug_rdp_access       = var.create_debug_rdp_access
  main_vnet_name                = module.dc-cac-network.virtual-network-name
  main_vnet_id                  = module.dc-cac-network.virtual-network-id
  dns-name                      = module.dc-cac-network.dns-name
}

module "active-directory-domain-vm" {
  source = "../../modules/dc/dc-vm"

  dc_vm_depends_on = [module.dc-cac-network.all-output, module.dc-cac-network-extra.*.all-output]

  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  active_directory_domain_name = "${var.active_directory_netbios_name}.dns.internal"
  ad_admin_username            = var.ad_admin_username
  ad_admin_password            = var.ad_admin_password
  ad_pass_secret_name          = var.ad_pass_secret_name
  key_vault_id                 = var.key_vault_id
  nic_id                       = module.dc-cac-network.dc-network-interface-id
  prefix                       = var.prefix
  application_id               = var.application_id
  aad_client_secret            = var.aad_client_secret
}

module "active-directory-domain-service" {
  source = "../../modules/dc/dc-service"

  dc_vm_setup_depends_on = [
    module.dc-cac-network.all-output,
    module.active-directory-domain-vm.domain-controller-name,
    module.active-directory-domain-vm.domain-controller-id,
    module.dc-cac-network.dc-association-id,
    module.dc-cac-network-extra.*.all-output
  ]

  domain_controller_virtual_machine_name      = module.active-directory-domain-vm.domain-controller-name
  domain_controller_virtual_machine_id        = module.active-directory-domain-vm.domain-controller-id
  domain_controller_virtual_machine_public_ip = module.dc-cac-network.dc-public-ip
  active_directory_domain_users_list_file     = var.ad_domain_users_list_file
  active_directory_domain_name                = "${var.active_directory_netbios_name}.dns.internal"
  ad_admin_username                           = var.ad_admin_username
  ad_admin_password                           = var.ad_admin_password
  ad_pass_secret_name                         = var.ad_pass_secret_name
  key_vault_id                                = var.key_vault_id
  application_id                              = var.application_id
  aad_client_secret                           = var.aad_client_secret
  tenant_id                                   = var.tenant_id
  safe_mode_admin_password                    = var.safe_mode_admin_password
}

module "active-directory-domain-configure" {
  source = "../../modules/dc/dc-configure"

  dc_configure_depends_on = [
    module.dc-cac-network.all-output,
    module.active-directory-domain-service.uploaded-scripts,
    module.active-directory-domain-service.uploaded-domain-users-list-count,
    module.dc-cac-network-extra.*.all-output
  ]

  application_id                         = var.application_id
  aad_client_secret                      = var.aad_client_secret
  resource_group_name                    = azurerm_resource_group.main.name
  domain_controller_virtual_machine_name = module.active-directory-domain-vm.domain-controller-name
}



module "windows-std-vm" {
  source = "../../modules/windows-std-vm"

  windows_host_vm_depends_on = [module.dc-cac-network.subnet-dc-id, module.active-directory-domain-configure.service-configured, module.dc-cac-network-extra.*.all-output]
  blob_depends_on = [azurerm_storage_account.storage, azurerm_storage_container.blob]

  workstations                 = module.workstation-map.windows-std-workstations
  resource_group_name          = azurerm_resource_group.main.name
  admin_name                   = var.windows_admin_username
  admin_password               = var.ad_admin_password
  pcoip_registration_code      = var.pcoip_registration_code
  domain_name                  = "${var.active_directory_netbios_name}.dns.internal"
  ad_service_account_username  = var.ad_admin_username
  ad_service_account_password  = var.ad_admin_password
  application_id               = var.application_id
  tenant_id                    = var.tenant_id
  aad_client_secret            = var.aad_client_secret
  key_vault_id                 = var.key_vault_id
  ad_pass_secret_name          = var.ad_pass_secret_name
  storage_account_name         = azurerm_storage_account.storage.name
  workstation_subnet_ids       = concat(module.dc-cac-network.subnet-workstation-ids, module.dc-cac-network-extra.subnet-workstation-ids)
  workstation_subnet_locations = concat(module.dc-cac-network.subnet-workstation-locations, module.dc-cac-network-extra.subnet-workstation-locations)

  enable_workstation_idle_shutdown = var.enable_workstation_idle_shutdown
  minutes_idle_before_shutdown     = var.minutes_idle_before_shutdown
  minutes_cpu_polling_interval     = var.minutes_cpu_polling_interval
}

module "windows-gfx-vm" {
  source = "../../modules/windows-gfx-vm"

  windows_host_vm_depends_on = [module.dc-cac-network.subnet-dc-id, module.active-directory-domain-configure.service-configured, module.dc-cac-network-extra.*.all-output]
  blob_depends_on = [azurerm_storage_account.storage, azurerm_storage_container.blob]

  workstations                 = module.workstation-map.windows-gfx-workstations
  resource_group_name          = azurerm_resource_group.main.name
  admin_name                   = var.windows_admin_username
  admin_password               = var.ad_admin_password
  pcoip_registration_code      = var.pcoip_registration_code
  domain_name                  = "${var.active_directory_netbios_name}.dns.internal"
  ad_service_account_username  = var.ad_admin_username
  ad_service_account_password  = var.ad_admin_password
  application_id               = var.application_id
  tenant_id                    = var.tenant_id
  aad_client_secret            = var.aad_client_secret
  key_vault_id                 = var.key_vault_id
  ad_pass_secret_name          = var.ad_pass_secret_name
  storage_account_name         = azurerm_storage_account.storage.name
  workstation_subnet_ids       = concat(module.dc-cac-network.subnet-workstation-ids, module.dc-cac-network-extra.subnet-workstation-ids)
  workstation_subnet_locations = concat(module.dc-cac-network.subnet-workstation-locations, module.dc-cac-network-extra.subnet-workstation-locations)

  enable_workstation_idle_shutdown = var.enable_workstation_idle_shutdown
  minutes_idle_before_shutdown     = var.minutes_idle_before_shutdown
  minutes_cpu_polling_interval     = var.minutes_cpu_polling_interval
}

module "centos-std-vm" {
  source = "../../modules/centos-std-vm"

  centos_std_depends_on = [module.dc-cac-network.subnet-dc-id, module.active-directory-domain-configure.service-configured, module.dc-cac-network-extra.*.all-output]

  workstations                 = module.workstation-map.centos-std-workstations
  resource_group_name          = azurerm_resource_group.main.name
  admin_name                   = var.centos_admin_username
  admin_password               = var.ad_admin_password
  pcoip_registration_code      = var.pcoip_registration_code
  domain_name                  = "${var.active_directory_netbios_name}.dns.internal"
  ad_service_account_username  = var.ad_admin_username
  ad_service_account_password  = var.ad_admin_password
  application_id               = var.application_id
  tenant_id                    = var.tenant_id
  aad_client_secret            = var.aad_client_secret
  key_vault_id                 = var.key_vault_id
  ad_pass_secret_name          = var.ad_pass_secret_name
  domain_controller_ip         = module.dc-cac-network.dc-private-ip
  workstation_subnet_ids       = concat(module.dc-cac-network.subnet-workstation-ids, module.dc-cac-network-extra.subnet-workstation-ids)
  workstation_subnet_locations = concat(module.dc-cac-network.subnet-workstation-locations, module.dc-cac-network-extra.subnet-workstation-locations)

  enable_workstation_idle_shutdown = var.enable_workstation_idle_shutdown
  minutes_idle_before_shutdown     = var.minutes_idle_before_shutdown
  minutes_cpu_polling_interval     = var.minutes_cpu_polling_interval
}

module "centos-gfx-vm" {
  source = "../../modules/centos-gfx-vm"

  centos_gfx_depends_on = [module.dc-cac-network.subnet-dc-id, module.active-directory-domain-configure.service-configured, module.dc-cac-network-extra.*.all-output]

  workstations                 = module.workstation-map.centos-gfx-workstations
  resource_group_name          = azurerm_resource_group.main.name
  admin_name                   = var.centos_admin_username
  admin_password               = var.ad_admin_password
  pcoip_registration_code      = var.pcoip_registration_code
  domain_name                  = "${var.active_directory_netbios_name}.dns.internal"
  ad_service_account_username  = var.ad_admin_username
  ad_service_account_password  = var.ad_admin_password
  application_id               = var.application_id
  tenant_id                    = var.tenant_id
  aad_client_secret            = var.aad_client_secret
  key_vault_id                 = var.key_vault_id
  ad_pass_secret_name          = var.ad_pass_secret_name
  domain_controller_ip         = module.dc-cac-network.dc-private-ip
  workstation_subnet_ids       = concat(module.dc-cac-network.subnet-workstation-ids, module.dc-cac-network-extra.subnet-workstation-ids)
  workstation_subnet_locations = concat(module.dc-cac-network.subnet-workstation-locations, module.dc-cac-network-extra.subnet-workstation-locations)

  enable_workstation_idle_shutdown = var.enable_workstation_idle_shutdown
  minutes_idle_before_shutdown     = var.minutes_idle_before_shutdown
  minutes_cpu_polling_interval     = var.minutes_cpu_polling_interval
}
