data "azurerm_client_config" "current" {}

data "azurerm_key_vault_secret" "secrets" {
  for_each = toset(var.vault_secrets)

  key_vault_id = azurerm_key_vault.this.id

  name = each.value

  depends_on = [
    azurerm_key_vault_secret.db_admin_password,
    azurerm_key_vault_secret.vmss_admin_password,
    azurerm_key_vault_secret.sql_admin_password
  ]
}

