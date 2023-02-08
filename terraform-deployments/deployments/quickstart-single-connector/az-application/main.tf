/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

resource "random_id" "app-name" {
  byte_length = 3
}

data "azuread_client_config" "current" {}

resource "azuread_application" "cam-application" {
  display_name = var.application_name
  owners = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "cam-service-principal" {
  application_id = azuread_application.cam-application.application_id
  owners = [data.azuread_client_config.current.object_id]
}

resource "azurerm_role_assignment" "vm-contributor-role" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azuread_service_principal.cam-service-principal.id
}

resource "azurerm_role_assignment" "reader-role" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.cam-service-principal.id
}

resource "azurerm_role_assignment" "contributor-role" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.cam-service-principal.id
}

resource "azuread_application_password" "client-secret" {
  end_date              = "2299-12-30T23:00:00Z"
  application_object_id = azuread_application.cam-application.id
}
