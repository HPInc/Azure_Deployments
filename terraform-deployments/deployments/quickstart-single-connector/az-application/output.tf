/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "app_application_id" {
  value = azuread_application.cam-application.application_id
}

output "client_secret" {
  value = random_string.client-secret-value.result
}

output "app_object_id" {
  value = azuread_application.cam-application.object_id
}

output "application_name" {
  value = azuread_application.cam-application.name
}
