/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */


resource "azurerm_user_assigned_identity" "managed-identity" {
  location            = var.location
  name                = var.managed_identity_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "vm-contributor-role" {
  scope              = data.azurerm_subscription.primary.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id       = azurerm_user_assigned_identity.managed-identity.principal_id
}

resource "azurerm_role_assignment" "reader-role" {
  scope              = data.azurerm_subscription.primary.id
  role_definition_name = "Reader"
  principal_id       = azurerm_user_assigned_identity.managed-identity.principal_id
}

resource "azurerm_role_assignment" "contributor-role" {
  scope              = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id       = azurerm_user_assigned_identity.managed-identity.principal_id
}
