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

  name                 = try(each.value.name, each.key)
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

resource "azurerm_private_dns_zone" "this" {
  for_each = try(var.env.private_dns_zone, {})

  name                = each.key
  resource_group_name = azurerm_resource_group.this.name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = try(var.env.private_dns_zone, {})

  name                  = split("/", azurerm_virtual_network.this.id)[8]
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false

  tags = local.tags
}

resource "azurerm_public_ip" "this" {
  for_each = try(var.env.public_ips, {})

  name                = try(each.value.name, "${local.resource_name_prefix}${each.key}-pip")
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = try(each.value.allocation_method, "Dynamic")
  sku                 = try(each.value.sku, "Basic")
  sku_tier            = try(each.value.sku_tier, "Regional")

  tags = local.tags
}

resource "azurerm_bastion_host" "this" {
  for_each = try(var.env.bastion_hosts, {})

  name                = try(each.value.name, "${local.resource_name_prefix}${each.key}-bastion")
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = try(each.value.sku, "Basic")
  tunneling_enabled   = try(each.value.tunneling_enabled, false)

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.this[each.value.subnet].id
    public_ip_address_id = azurerm_public_ip.this[each.value.public_ip].id
  }

  tags = local.tags
}
