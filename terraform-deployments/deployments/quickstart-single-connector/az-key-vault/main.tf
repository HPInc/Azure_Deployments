resource "random_id" "quickstart-name" {
  byte_length = 3
}

resource "azurerm_key_vault" "secrets" {
  name                = "keyvault-${random_id.quickstart-name.hex}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
}

resource "azurerm_key_vault_access_policy" "object-id" {
  key_vault_id = azurerm_key_vault.secrets.id
  object_id    = var.object_id
  tenant_id    = data.azurerm_client_config.current.tenant_id

  secret_permissions = [
    "set",
    "list",
    "get",
    "delete",
    "recover",
    "backup",
    "restore",
  ]
}

resource "azurerm_key_vault_access_policy" "app-object-id" {
  key_vault_id = azurerm_key_vault.secrets.id
  object_id    = var.app_object_id
  tenant_id    = data.azurerm_client_config.current.tenant_id

  secret_permissions = [
    "set",
    "list",
    "get",
    "delete",
    "recover",
    "backup",
    "restore",
  ]
}

resource "azurerm_key_vault_secret" "pcoip-registration-code" {
  name         = "pcoipRegistrationCode"
  value        = var.pcoip_registration_code
  key_vault_id = azurerm_key_vault.secrets.id
  depends_on = [azurerm_key_vault_access_policy.object-id, azurerm_key_vault_access_policy.app-object-id]
}

resource "azurerm_key_vault_secret" "safe-mode-admin-password" {
  name         = "safeModeAdminPassword"
  value        = var.safe_mode_admin_password
  key_vault_id = azurerm_key_vault.secrets.id
  depends_on = [azurerm_key_vault_access_policy.object-id, azurerm_key_vault_access_policy.app-object-id]
}

resource "azurerm_key_vault_secret" "ad-admin-password" {
  name         = "adAdminPassword"
  value        = var.ad_admin_password
  key_vault_id = azurerm_key_vault.secrets.id
  depends_on = [azurerm_key_vault_access_policy.object-id, azurerm_key_vault_access_policy.app-object-id]
}

resource "azurerm_key_vault_secret" "cac-token" {
  name         = "cacToken"
  value        = var.cac_token
  key_vault_id = azurerm_key_vault.secrets.id
  depends_on = [azurerm_key_vault_access_policy.object-id, azurerm_key_vault_access_policy.app-object-id]
}

