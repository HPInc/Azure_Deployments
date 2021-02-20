data "azurerm_subscription" "primary" {}

data "azurerm_client_config" "current" {}

locals {
  resource_group_name = "single_connector_app_${random_id.quickstart-name.hex}"
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
  application_name = local.resource_group_name
}
