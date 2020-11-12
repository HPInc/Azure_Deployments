/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

module "workstation-map" {
  source = "../../modules/workstation-map"

  # Populate the module properties
  workstations                = var.workstations
}

resource "azurerm_resource_group" "main" {
  location = module.workstation-map.virtual-network-locations[0]
  name     = var.resource_group_name
}

module "dc-cac-network" {
  source = "../../modules/network/dc-cac"

  # Module is dependent on the resource group
  dc_cac_network_depends_on = [azurerm_resource_group.main.id]

  # Populate the module properties
  resource_group_name           = azurerm_resource_group.main.name
  locations                     = module.workstation-map.virtual-network-locations
  vnet_peer_to_peer_links       = module.workstation-map.virtual-network-peer-to-peer-links

  prefix                        = var.prefix
  vnet_name                     = var.vnet_name
  dc_subnet_name                = var.dc_subnet_name
  workstation_subnet_name       = var.workstation_subnet_name

  active_directory_netbios_name = var.active_directory_netbios_name

  # Debug flags
  create_debug_rdp_access       = var.create_debug_rdp_access
  create_debug_public_ips       = var.create_debug_public_ips
}

module "cac-network" {
  source = "../../modules/cac/cac-network"

  # Module is dependent on the resource group
  cac_network_depends_on = [azurerm_resource_group.main.id]

  # Populate the module properties
  prefix                        = var.prefix
  resource_group_name           = azurerm_resource_group.main.name
  locations                     = module.workstation-map.virtual-network-locations

  # The number of cac network items is based on the configuration
  cac_configuration              = var.cac_configuration

  network_security_group_ids     = module.dc-cac-network.network-security-group-ids
  azurerm_virtual_network_names  = module.dc-cac-network.virtual-network-names
}

module "active-directory-domain-vm" {
  source = "../../modules/dc/dc-vm"

  # Module is dependent on the the domain controller network setup
  dc_vm_depends_on = [
    module.dc-cac-network.all-output
  ]

  # Populate the module properties
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  active_directory_domain_name  = "${var.active_directory_netbios_name}.dns.internal"
  ad_admin_username             = var.ad_admin_username
  ad_admin_password             = var.ad_admin_password
  dc_machine_type               = var.dc_machine_type
  nic_id                        = module.dc-cac-network.dc-network-interface-id
  prefix                        = var.prefix
}

module "active-directory-domain-service" {
  source = "../../modules/dc/dc-service"

  # Module is dependent on domain controller vm deployment
  dc_vm_setup_depends_on = [
    module.dc-cac-network.all-output,
    module.active-directory-domain-vm.domain-controller-name,
    module.active-directory-domain-vm.domain-controller-id
  ]

  # Populate the module properties
  domain_controller_virtual_machine_name = module.active-directory-domain-vm.domain-controller-name
  domain_controller_virtual_machine_id = module.active-directory-domain-vm.domain-controller-id
  domain_controller_virtual_machine_public_ip = module.dc-cac-network.dc-public-ip
  active_directory_domain_users_list_file = var.ad_domain_users_list_file

  active_directory_domain_name  = "${var.active_directory_netbios_name}.dns.internal"
  ad_admin_username             = var.ad_admin_username
  ad_admin_password             = var.ad_admin_password
  ad_pass_secret_name           = var.ad_pass_secret_name
  key_vault_id                  = var.key_vault_id
  application_id                = var.application_id
  aad_client_secret             = var.aad_client_secret
  tenant_id                     = var.tenant_id
  safe_admin_pass_secret_id     = var.safe_admin_pass_secret_id
  safe_mode_admin_password      = var.safe_mode_admin_password
}

module "active-directory-domain-configure" {
  source = "../../modules/dc/dc-configure"

  # Module is dependent on domain controller service installation completion
  dc_configure_depends_on = [
    module.dc-cac-network.all-output,
    module.active-directory-domain-service.uploaded-scripts,
    module.active-directory-domain-service.uploaded-domain-users-list-count
  ]

  # Populate the module properties
  resource_group_name                    = var.resource_group_name
  domain_controller_virtual_machine_name = module.active-directory-domain-vm.domain-controller-name               
}

module "cac-vm" {
  source = "../../modules/cac/cac-vm"

  # Module is dependent on the configuration of the domain controller
  cac_depends_on = [
    module.dc-cac-network.all-output,
    module.active-directory-domain-configure.service-configured
  ]

  # Populate the module properties
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location

  # The number of cac VMs is based on the configuration
  cac_configuration             = var.cac_configuration

  prefix                      = var.prefix
  pcoip_registration_code     = var.pcoip_registration_code
  domain_name                 = "${var.active_directory_netbios_name}.dns.internal"
  domain_controller_ip        = module.dc-cac-network.dc-private-ip
  domain_group                = var.domain_group
  ad_service_account_username = var.ad_admin_username
  ad_service_account_password = var.ad_admin_password
  nic_ids                     = module.cac-network.cac-network-interface-ids
  host_name                   = "${var.prefix}-cac-vm"
  machine_type                = var.cac_machine_type
  cac_admin_user              = var.cac_admin_username
  cac_admin_password          = var.cac_admin_password
  dns_zone_id                 = module.dc-cac-network.private-dns-zone-id
  application_id              = var.application_id
  aad_client_secret           = var.aad_client_secret
  tenant_id                   = var.tenant_id
  pcoip_secret_id             = var.pcoip_secret_id
  ad_pass_secret_id           = var.ad_pass_secret_id
  cac_token_secret_id         = var.cac_token_secret_id
  _artifactsLocation          = var._artifactsLocation
}

module "cac-configuration" {
  source = "../../modules/cac/cac-configure"

  # Make sure module creation is dependent on the resource group and a fully setup network
  cac_configure_depends_on = [
    module.dc-cac-network.all-output,
    module.cac-vm.cac-vm-ids
  ]

  # The number of cac VMs is based on the configuration
  cac_configuration             = var.cac_configuration

  # Populate the module properties
  cam_url                     = var.cam_url
  pcoip_registration_code     = var.pcoip_registration_code
  domain_name                 = "${var.active_directory_netbios_name}.dns.internal"
  domain_controller_ip        = module.dc-cac-network.dc-private-ip
  domain_group                = var.domain_group
  ad_service_account_username = var.ad_admin_username
  ad_service_account_password = var.ad_admin_password
  cac_admin_user              = var.cac_admin_username
  cac_admin_password          = var.cac_admin_password
  cac_installer_url           = var.cac_installer_url
  ssl_key                     = var.ssl_key
  ssl_cert                    = var.ssl_cert
  cac_ips                     = module.cac-network.cac-public-ips
  cac_vm_ids                  = module.cac-vm.cac-vm-ids
  application_id              = var.application_id
  aad_client_secret           = var.aad_client_secret
  tenant_id                   = var.tenant_id
  pcoip_secret_id             = var.pcoip_secret_id
  ad_pass_secret_id           = var.ad_pass_secret_id
  cac_token_secret_id         = var.cac_token_secret_id
  _artifactsLocation          = var._artifactsLocation
}

module "load-balancer" {
  source = "../../modules/network/load-balancer"

  # Make sure module creation is dependent on the resource group a fully setup network and a cac
  load_balancer_depends_on = [
    module.dc-cac-network.all-output,
    module.active-directory-domain-configure.service-configured,
    module.cac-vm.cac-vm-ids,
    module.cac-configuration.cac-vm-configure
  ]

  # Populate the module properties
  resource_group_name                       = azurerm_resource_group.main.name
  locations                                 = module.workstation-map.virtual-network-locations
  cac_configuration                         = var.cac_configuration
  cac_network_interface_ids                 = module.cac-network.cac-network-interface-ids
  cac_network_interface_primary_config_name = module.cac-network.cac-network-interface-primary-config-name
}

module "windows-host-network" {
  source = "../../modules/windows-host/windows-host-network"

  # Make sure module creation is dependent on the resource group a fully setup network and a cac
  windows_host_network_depends_on = [
    module.dc-cac-network.all-output,
    module.active-directory-domain-configure.service-configured,
    module.cac-vm.cac-vm-ids,
    module.cac-configuration.cac-vm-configure
  ]

  # Populate the module properties
  workstations                 = module.workstation-map.windows-workstations

  resource_group_name          = azurerm_resource_group.main.name
  workstation_subnet_ids       = module.dc-cac-network.subnet-workstation-ids
  workstation_subnet_locations = module.dc-cac-network.subnet-workstation-locations
  nat_gateway_ids              = module.dc-cac-network.nat-gateway-ids
}


module "windows-host-vm" {
  source = "../../modules/windows-host/windows-host-vm"

  # Make sure module creation is dependent on the resource group a fully setup network and a cac
  windows_host_vm_depends_on = [
    module.dc-cac-network.all-output,
    module.active-directory-domain-configure.service-configured,
    module.cac-vm.cac-vm-ids,
    module.cac-configuration.cac-vm-configure,
    module.windows-host-network.windows-host-private-ips
  ]

  # Populate the module properties
  workstations                = module.workstation-map.windows-workstations

  resource_group_name         = azurerm_resource_group.main.name
  admin_name                  = var.windows_admin_username
  admin_password              = var.windows_admin_password

  windows_host_nic_ids        = module.windows-host-network.windows-host-nic-ids
}

module "windows-host-configure" {
  source = "../../modules/windows-host/windows-host-configure"

  # Make sure module creation is dependent on the resource group a fully setup network and a cac
  windows_host_configure_depends_on = [
    module.dc-cac-network.all-output,
    module.cac-vm.cac-vm-ids,
    module.cac-configuration.cac-vm-configure,
    module.windows-host-network.windows-host-private-ips,
    module.windows-host-vm.windows-host-vm-ids
  ]

  # Populate the module properties
  workstations                = module.workstation-map.windows-workstations

  resource_group_name         = azurerm_resource_group.main.name
  pcoip_registration_code     = var.pcoip_registration_code
  domain_name                 = "${var.active_directory_netbios_name}.dns.internal"
  ad_service_account_username = var.ad_admin_username
  ad_service_account_password = var.ad_admin_password
  application_id              = var.application_id
  tenant_id                   = var.tenant_id
  aad_client_secret           = var.aad_client_secret
  pcoip_secret_id             = var.pcoip_secret_id
  ad_pass_secret_id           = var.ad_pass_secret_id
  _artifactsLocation          = var._artifactsLocation
  _artifactsLocationSasToken  = var._artifactsLocationSasToken

  windows-host-vm-ids         = module.windows-host-vm.windows-host-vm-ids
  windows-host-vm-names       = module.windows-host-vm.windows-host-vm-names
  windows-host-vm-public-ips  = module.windows-host-vm.windows-host-vm-public-ips
}

module "centos-host-network" {
  source = "../../modules/centos-host/centos-host-network"

  # Make sure module creation is dependent on the resource group, a fully set up network, and a cac
  centos_host_network_depends_on = [
    module.dc-cac-network.all-output,
    module.active-directory-domain-configure.service-configured,
    module.cac-vm.cac-vm-ids,
    module.cac-configuration.cac-vm-configure
  ] 

  # Populate the module properties
  workstations                = module.workstation-map.linux-workstations

  resource_group_name         = azurerm_resource_group.main.name
  workstation_subnet_ids       = module.dc-cac-network.subnet-workstation-ids
  workstation_subnet_locations = module.dc-cac-network.subnet-workstation-locations
  nat_gateway_ids              = module.dc-cac-network.nat-gateway-ids
}

module "centos-host-vm" {
    source = "../../modules/centos-host/centos-host-vm"

  # Make sure module creation is dependent on the resource group a fully setup network and a cac
  centos_host_vm_depends_on = [
    module.dc-cac-network.all-output,
    module.active-directory-domain-configure.service-configured,
    module.cac-vm.cac-vm-ids,
    module.cac-configuration.cac-vm-configure,
    module.centos-host-network.centos-host-private-ips
  ]

  # Populate the module properties
  workstations                = module.workstation-map.linux-workstations

  resource_group_name         = azurerm_resource_group.main.name
  admin_name                  = var.centos_admin_username
  admin_password              = var.centos_admin_password

  centos_host_nic_ids         = module.centos-host-network.centos-host-nic-ids
}

module "centos-host-configure" {
  source = "../../modules/centos-host/centos-host-configure"

  # Make sure module creation is dependent on the resource group a fully setup network and a cac
  centos_host_configure_depends_on = [
    module.dc-cac-network.all-output,
    module.cac-vm.cac-vm-ids,
    module.cac-configuration.cac-vm-configure,
    module.centos-host-network.centos-host-private-ips,
    module.centos-host-vm.centos-host-vm-ids,
  ]

  # Populate the module properties
  workstations = module.workstation-map.linux-workstations

  resource_group_name         = azurerm_resource_group.main.name
  pcoip_registration_code     = var.pcoip_registration_code
  domain_name                 = "${var.active_directory_netbios_name}.dns.internal"
  ad_service_account_username = var.ad_admin_username
  ad_service_account_password = var.ad_admin_password
  application_id              = var.application_id
  tenant_id                   = var.tenant_id
  aad_client_secret           = var.aad_client_secret
  pcoip_secret_id             = var.pcoip_secret_id
  ad_pass_secret_id           = var.ad_pass_secret_id
  _artifactsLocation          = var._artifactsLocation
  _artifactsLocationSasToken  = var._artifactsLocationSasToken

  admin_name                  = var.centos_admin_username
  admin_password              = var.centos_admin_password
  domain_controller_ip        = module.dc-cac-network.dc-private-ip

  centos-host-vm-ids          = module.centos-host-vm.centos-host-vm-ids
  centos-host-vm-names        = module.centos-host-vm.centos-host-vm-names
  centos-host-vm-public-ips   = module.centos-host-vm.centos-host-vm-public-ips
}
