module "application_insights" {
  source = "../../modules/azure/application-insights"

  name                       = "${local.resource_name_prefix}-appi"
  location                   = azurerm_resource_group.this["primary"].location
  resource_group_name        = azurerm_resource_group.this["primary"].name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this["primary"].id
  application_type           = var.env.application_insights.application_type

  tags = local.tags
}
