resource "azurerm_key_vault_secret" "db" {
  for_each = {
    "postgresql-db-host" : azurerm_postgresql_flexible_server.this.fqdn,
    "postgresql-db-name" : azurerm_postgresql_flexible_server_database.this["drone"].name
  }

  key_vault_id = azurerm_key_vault.this.id
  name         = each.key
  value        = each.value

  depends_on = [
    module.kv_admin
  ]

  tags = local.tags
}
