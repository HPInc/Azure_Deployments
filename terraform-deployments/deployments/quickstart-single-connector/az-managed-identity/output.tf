/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "managed_identity_id" {
  value = azurerm_user_assigned_identity.managed-identity.id
}

output "managed_identity_principal_id" {
  value = azurerm_user_assigned_identity.managed-identity.principal_id
  sensitive = true
}

output "managed_identity_client_id" {
  value = azurerm_user_assigned_identity.managed-identity.client_id
}

output "managed_identity_name" {
  value = azurerm_user_assigned_identity.managed-identity.name
}
