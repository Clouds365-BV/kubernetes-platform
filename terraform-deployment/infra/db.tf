resource "azurerm_mysql_flexible_server" "this" {
  name                   = "${local.resource_name_prefix}-mysql"
  resource_group_name    = azurerm_resource_group.this.name
  location               = azurerm_resource_group.this.location
  administrator_login    = azurerm_key_vault_secret.this[var.env.databases.mysql.administrator_login].value
  administrator_password = azurerm_key_vault_secret.this[var.env.databases.mysql.administrator_password].value
  delegated_subnet_id    = azurerm_subnet.this[var.env.databases.mysql.subnet].id
  backup_retention_days  = 7
  #public_network_access_enabled = var.env.databases.mysql.public_network_access_enabled
  sku_name            = var.env.databases.mysql.sku_name
  storage {
    auto_grow_enabled = true
    size_gb           = var.env.databases.mysql.storage_gb
  }
  version                      = var.env.databases.mysql.version
  geo_redundant_backup_enabled = true


  lifecycle {
    ignore_changes = [
      zone
    ]
    #prevent_destroy = true
  }

  depends_on = [
    azurerm_subnet.this,
    azurerm_private_dns_zone.this
  ]

  tags = local.tags
}

module "diagnostic_settings_mysql" {
  source = "../../modules/azure/monitor/diagnostic-settings"

  name                       = "mysql-diagnostic-settings"
  target_resource_id         = azurerm_mysql_flexible_server.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  logs = [
    {
      category_group = "allLogs"
    },
    {
      category_group = "audit"
    }
  ]
  metrics = [
    {
      category = "AllMetrics"
    }
  ]
}

resource "azurerm_mysql_flexible_server_configuration" "this" {
  for_each = var.env.databases.mysql.parameters

  resource_group_name = azurerm_mysql_flexible_server.this.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this.name
  name                = each.key
  value               = each.value
}

resource "azurerm_mysql_flexible_database" "this" {
  for_each = var.env.databases.mysql.databases

  name                = each.key
  resource_group_name = azurerm_mysql_flexible_server.this.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this.name
  charset             = try(each.value.charset, "utf8mb3")
  collation           = try(each.value.collation, "utf8mb3_unicode_ci")

  # prevent the possibility of accidental data loss
  lifecycle {
    #prevent_destroy = true
  }
}
