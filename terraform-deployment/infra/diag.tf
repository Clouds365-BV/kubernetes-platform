resource "azurerm_log_analytics_workspace" "this" {
  name                = "${local.resource_name_prefix}-log"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = var.env.log_analytics_workspace.sku_name
  retention_in_days   = var.env.log_analytics_workspace.retention_in_days

  tags = local.tags
}

module "application_insights" {
  source = "../../modules/azure/application-insights"

  name                       = "${local.resource_name_prefix}-appi"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  application_type           = var.env.application_insights.application_type

  tags = local.tags
}
