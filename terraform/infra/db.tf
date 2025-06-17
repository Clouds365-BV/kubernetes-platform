resource "azurerm_mysql_flexible_server" "this" {
  name                   = "${local.resource_name_prefix}-mysql"
  resource_group_name    = azurerm_resource_group.this["primary"].name
  location               = azurerm_resource_group.this["primary"].location
  administrator_login    = azurerm_key_vault_secret.this[var.env.databases.mysql.administrator_login].value
  administrator_password = azurerm_key_vault_secret.this[var.env.databases.mysql.administrator_password].value
  delegated_subnet_id    = azurerm_subnet.this[var.env.databases.mysql.subnet].id
  backup_retention_days  = 7
  #public_network_access_enabled = var.env.databases.mysql.public_network_access_enabled
  sku_name            = var.env.databases.mysql.sku_name
  private_dns_zone_id = azurerm_private_dns_zone.this["privatelink.mysql.database.azure.com"].id
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
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this["primary"].id
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

# Regional MySQL instances for geo-redundancy
resource "azurerm_mysql_flexible_server" "regional" {
  for_each = { for k, v in var.regions : k => v if k != "primary" }

  name                   = "${local.resource_name_prefix}-${each.key}-mysql"
  location               = azurerm_resource_group.this[each.key].location
  resource_group_name    = azurerm_resource_group.this[each.key].name
  administrator_login    = "mysqladmin"
  administrator_password = azurerm_key_vault_secret.mysql_password.value
  sku_name               = "GP_Standard_D2ds_v4"
  backup_retention_days  = 7
  version                = "5.7"

  storage {
    auto_grow_enabled = true
    size_gb           = 50
  }

  high_availability {
    mode = "ZoneRedundant"
  }

  geo_redundant_backup_enabled = true

  tags = local.tags
}

resource "azurerm_mysql_flexible_database" "ghost" {
  for_each = { for k, v in var.regions : k => v if k != "primary" }

  name                = "ghost"
  resource_group_name = azurerm_resource_group.this[each.key].name
  server_name         = azurerm_mysql_flexible_server.regional[each.key].name
  charset             = "utf8"
  collation           = "utf8_general_ci"
}

# Geo-replication configuration through flexible server settings
resource "azurerm_mysql_flexible_server_configuration" "replication" {
  for_each = { for k, v in var.regions : k => v if k != "primary" }

  name                = "replicate_wild_ignore_table"
  resource_group_name = azurerm_resource_group.this[each.key].name
  server_name         = azurerm_mysql_flexible_server.regional[each.key].name
  value               = "mysql.%"
}

resource "azurerm_storage_account" "security" {
  for_each = var.regions

  name                     = "${local.resource_name_prefix}${each.key}sec"
  resource_group_name      = azurerm_resource_group.this[each.key].name
  location                 = azurerm_resource_group.this[each.key].location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = local.tags
}

# Private endpoints for MySQL servers
resource "azurerm_private_endpoint" "mysql" {
  for_each = var.regions

  name                = "${local.resource_name_prefix}-${each.key}-mysql-endpoint"
  location            = azurerm_resource_group.this[each.key].location
  resource_group_name = azurerm_resource_group.this[each.key].name
  subnet_id           = azurerm_subnet.this["${each.key}-endpoints"].id

  private_service_connection {
    name                           = "${local.resource_name_prefix}-${each.key}-mysql-connection"
    private_connection_resource_id = azurerm_mysql_server.this[each.key].id
    is_manual_connection           = false
    subresource_names              = ["mysqlServer"]
  }

  private_dns_zone_group {
    name                 = "mysql-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.this["privatelink.${each.value.location}.database.windows.net"].id]
  }

  tags = local.tags
}
