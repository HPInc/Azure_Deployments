provider "azuread" {
}

resource "random_id" "app-name" {
  byte_length = 3
}

resource "azuread_application" "cam-application" {
  name = var.application_name
}

resource "azuread_service_principal" "cam-service-principal" {
  application_id = azuread_application.cam-application.application_id
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

resource "random_string" "client-secret-value" {
  length           = 32
  special          = true
  override_special = "-_.~"
}

resource "azuread_application_password" "client-secret" {
  end_date              = "2299-12-30T23:00:00Z"
  application_object_id = azuread_application.cam-application.id
  value                 = random_string.client-secret-value.result
}
