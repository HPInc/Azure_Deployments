output "key-vault-secrets" {
  value = {
    "pcoip_registration_code" : azurerm_key_vault_secret.pcoip-registration-code.id,
    "safe_mode_admin_password" : azurerm_key_vault_secret.safe-mode-admin-password.id,
    "ad_admin_password" : azurerm_key_vault_secret.ad-admin-password.id,
    "ad_pass_secret_name" : azurerm_key_vault_secret.ad-admin-password.name,
    "cac_token" : azurerm_key_vault_secret.cac-token.id,
    "key_vault_id" : azurerm_key_vault.secrets.id
  }
}
