/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  prefix         = var.prefix != "" ? "${var.prefix}-" : ""
  cas_mgr_script = "get-cac-token.py"
  num_regions    = length(var.locations)
}

resource "azurerm_storage_blob" "get-cac-token-script" {
  depends_on = [
    var.blob_depends_on
  ]
  name                   = local.cas_mgr_script
  storage_account_name   = var.storage_account_name
  storage_container_name = var.storage_account_name
  type                   = "Block"
  source                 = "${path.module}/${local.cas_mgr_script}"
}

module "cac-regional" {
  source = "../cac-regional"

  count = var.is_private == false ? local.num_regions : 0

  prefix = var.prefix
  cac_subnet_depends_on     = var.cac_subnet_depends_on
  location                  = var.locations[count.index]
  instance_count            = var.cac_count_list[count.index]
  virtual_network_name      = var.azurerm_virtual_network_names[count.index]
  network_security_group_id = var.network_security_group_ids[count.index]
  cac_subnet_cidr           = var.cac_subnet_cidr#["10.0.3.0/24"]
  cac_subnet_name           = "cac-${var.resource_group_name}"
  cas_mgr_setup_script_url   = azurerm_storage_blob.get-cac-token-script.url
  cas_mgr_deployment_sa_file = var.cas_mgr_deployment_sa_file
  cas_mgr_url                = var.cas_mgr_url
  cas_mgr_insecure           = var.cas_mgr_insecure
  cas_mgr_script             = local.cas_mgr_script

  private_container_url       = var.private_container_url
  storage_account_name        = var.storage_account_name
  resource_group_name         = var.resource_group_name
  ad_service_account_username = var.ad_service_account_username
  ad_service_account_password = var.ad_service_account_password
  domain_controller_ip        = var.domain_controller_ip
  domain_name                 = var.domain_name

  ssl_key  = var.ssl_key
  ssl_cert = var.ssl_cert

  cac_admin_user      = var.cac_admin_user
  cac_admin_password  = var.cac_admin_password
  application_id      = var.application_id
  aad_client_secret   = var.aad_client_secret
  key_vault_id        = var.key_vault_id
  tenant_id           = var.tenant_id
  ad_pass_secret_name = var.ad_pass_secret_name

  storage_connection_string = var.storage_connection_string
  private_container_name    = var.private_container_name

  aadds_resource_group = var.aadds_resource_group
}

module "cac-regional-private" {
  source = "../cac-regional-private"

  count = var.is_private == true ? local.num_regions : 0
  cac_subnet_depends_on = var.cac_subnet_depends_on
  cac_nat_depends_on    = var.cac_nat_depends_on
  prefix = var.prefix

  location                  = var.locations[count.index]
  instance_count            = var.cac_count_list[count.index]
  virtual_network_name      = var.azurerm_virtual_network_names[count.index]
  network_security_group_id = var.network_security_group_ids[count.index]
  cac_subnet_cidr           = var.cac_subnet_cidr#["10.${count.index}.3.0/24"]

  cas_mgr_setup_script_url   = azurerm_storage_blob.get-cac-token-script.url
  cas_mgr_deployment_sa_file = var.cas_mgr_deployment_sa_file
  cas_mgr_url                = var.cas_mgr_url
  cas_mgr_insecure           = var.cas_mgr_insecure
  cas_mgr_script             = local.cas_mgr_script

  private_container_url       = var.private_container_url
  storage_account_name        = var.storage_account_name
  resource_group_name         = var.resource_group_name
  ad_service_account_username = var.ad_service_account_username
  ad_service_account_password = var.ad_service_account_password
  domain_controller_ip        = var.domain_controller_ip
  domain_name                 = var.domain_name

  ssl_key  = var.ssl_key
  ssl_cert = var.ssl_cert

  cac_admin_user      = var.cac_admin_user
  cac_admin_password  = var.cac_admin_password
  application_id      = var.application_id
  aad_client_secret   = var.aad_client_secret
  key_vault_id        = var.key_vault_id
  tenant_id           = var.tenant_id
  ad_pass_secret_name = var.ad_pass_secret_name

  storage_connection_string = var.storage_connection_string
  private_container_name    = var.private_container_name
  aadds_resource_group      = var.aadds_resource_group
  cas_mgr_internal_ip       = var.cas_mgr_internal_ip
  cas_mgr_public_ip         = var.cas_mgr_public_ip
  cas_mgr_public_ip_id      = var.cas_mgr_public_ip_id

  fw_name       = var.fw_name
  cac_fw_public = var.cac_fw_public
  fw_internal   = var.fw_internal
}