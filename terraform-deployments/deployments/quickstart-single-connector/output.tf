output "ids" {
  value = {
    "tenant_id" : data.azurerm_subscription.primary.tenant_id,
    "subscription_id" : data.azurerm_subscription.primary.subscription_id,
    "resource_group_name" : azurerm_resource_group.primary.name,
    "app_object_id" : module.azuread_application.app_object_id,
    "application_name" : module.azuread_application.application_name,
    "application_id" : module.azuread_application.app_application_id,
    "client_secret" : module.azuread_application.client_secret
  }
}
