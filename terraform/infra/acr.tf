resource "azurerm_container_registry" "this" {
  name                          = replace("${local.resource_name_prefix}-acr", "-", "")
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  sku                           = "Standard"
  admin_enabled                 = true
  public_network_access_enabled = false
  anonymous_pull_enabled        = false

  tags = local.tags
}

module "acr_k8s_pull" {
  source = "../../modules/azure/authorization/role-assignment"

  object_id            = azurerm_user_assigned_identity.k8s.principal_id
  role_definition_name = "AcrPull"
  resource_id          = azurerm_container_registry.this.id
}

module "diagnostic_settings_acr" {
  source = "../../modules/azure/monitor/diagnostic-settings"

  name                       = "acr-diagnostic-settings"
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
