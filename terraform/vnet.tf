resource "azurerm_virtual_network" "this" {
  name                = "${local.resource_name_prefix}-vnet"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.env.vnet.address_space

  tags = local.tags
}

module "diagnostic_settings_vnet" {
  source = "../modules/azure/monitor/diagnostic-settings"

  name                       = "vnet-diagnostic-settings"
  target_resource_id         = azurerm_virtual_network.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  logs = [
    {
      category_group = "allLogs"
    }
  ]
  metrics = [
    {
      category = "AllMetrics"
    }
  ]
}

resource "azurerm_subnet" "this" {
  for_each = try(var.env.vnet.subnets, {})

  name                 = each.key
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = try(each.value.service_endpoints, null)

  dynamic "delegation" {
    for_each = try(each.value.delegations, {})

    content {
      name = delegation.key
      service_delegation {
        name    = delegation.value.name
        actions = try(delegation.value.actions, null)
      }
    }
  }
}
