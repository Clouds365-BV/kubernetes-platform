resource "azurerm_container_registry" "this" {
  name                          = "${local.resource_name_prefix}-acr"
  resource_group_name           = azurerm_resource_group.this["primary"].name
  location                      = azurerm_resource_group.this["primary"].location
  sku                           = "Standard"
  admin_enabled                 = true
  public_network_access_enabled = true
  anonymous_pull_enabled        = false

  tags = local.tags
}

module "acr_k8s_pull" {
  source = "../modules/azure/authorization/role-assignment"

  object_id            = azurerm_user_assigned_identity.k8s["primary"].principal_id
  role_definition_name = "AcrPull"
  resource_id          = azurerm_container_registry.this.id
}

module "diagnostic_settings_acr" {
  source = "../modules/azure/monitor/diagnostic-settings"

  name                       = "acr-diagnostic-settings"
  target_resource_id         = azurerm_container_registry.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this["primary"].id
  logs                       = local.diagnostic_settings.logs
  metrics                    = local.diagnostic_settings.metrics
}
