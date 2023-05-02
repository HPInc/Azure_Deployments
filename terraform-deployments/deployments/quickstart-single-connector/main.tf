/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

data "azurerm_subscription" "primary" {}

data "azurerm_client_config" "current" {}

locals {
  resource_group_name = "single_connector_keyvault_${random_id.quickstart-name.hex}"
}

resource "azurerm_resource_group" "primary" {
  name     = local.resource_group_name
  location = var.location
}

resource "random_id" "quickstart-name" {
  byte_length = 3
}

module "azuread_application" {
  source           = ".//az-application"
  count            = var.auth_method == "Service_Principal" ? 1 : 0
  application_name = local.resource_group_name
}

module "azure_managed_identity" {
  source                = ".//az-managed-identity"
  count                 = var.auth_method == "Managed_Identity" ? 1 : 0
  managed_identity_name = "single_connector_im_${random_id.quickstart-name.hex}"
  resource_group_name   = azurerm_resource_group.primary.name
  location              = var.location
}