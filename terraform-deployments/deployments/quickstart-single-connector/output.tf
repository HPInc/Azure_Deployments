/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "ids" {
  value = {
    "tenant_id" : data.azurerm_subscription.primary.tenant_id,
    "subscription_id" : data.azurerm_subscription.primary.subscription_id,
    "resource_group_name" : azurerm_resource_group.primary.name,
    "random_hex_id" : random_id.quickstart-name.hex,
    "app_object_id" : length(module.azuread_application) > 0 ? module.azuread_application[0].app_object_id : null,
    "application_name" : length(module.azuread_application) > 0 ? module.azuread_application[0].application_name : null,
    "application_id" : length(module.azuread_application) > 0 ? module.azuread_application[0].app_application_id : null,
    "client_secret" : length(module.azuread_application) > 0 ? module.azuread_application[0].client_secret : null,
    "managed_identity_id" : length(module.azure_managed_identity) > 0 ? module.azure_managed_identity[0].managed_identity_id : null,
    "managed_identity_name" : length(module.azure_managed_identity) > 0 ? module.azure_managed_identity[0].managed_identity_name : null,
    "managed_identity_principal_id" : length(module.azure_managed_identity) > 0 ? module.azure_managed_identity[0].managed_identity_principal_id : null,
    "managed_identity_client_id" : length(module.azure_managed_identity) > 0 ? module.azure_managed_identity[0].managed_identity_client_id : null
  }
  sensitive = true
}