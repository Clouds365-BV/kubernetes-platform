resource "azurerm_virtual_network" "this" {
  for_each = var.regions

  name                = "${local.resource_name_prefix}-${each.key}-vnet"
  location            = azurerm_resource_group.this[each.key].location
  resource_group_name = azurerm_resource_group.this[each.key].name
  address_space       = each.value.vnet.address_space

  tags = local.tags
}

# Virtual network peering for multi-region connectivity
resource "azurerm_virtual_network_peering" "region_peers" {
  for_each = {
    for pair in flatten([
      for region_key, region in var.regions : [
        for peer_key, peer in var.regions :
        {
          source_region  = region_key
          target_region  = peer_key
          source_vnet_id = azurerm_virtual_network.this[region_key].id
          target_vnet_id = azurerm_virtual_network.this[peer_key].id
        } if region_key != peer_key
      ]
    ]) : "${pair.source_region}-to-${pair.target_region}" => pair
  }

  name                         = "peer-${each.value.source_region}-to-${each.value.target_region}"
  resource_group_name          = azurerm_resource_group.this[each.value.source_region].name
  virtual_network_name         = azurerm_virtual_network.this[each.value.source_region].name
  remote_virtual_network_id    = each.value.target_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

module "diagnostic_settings_vnet" {
  source   = "../../modules/azure/monitor/diagnostic-settings"
  for_each = var.regions

  name                       = "${each.key}-vnet-diagnostic-settings"
  target_resource_id         = azurerm_virtual_network.this[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this[each.key].id
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
  for_each = {
    for subnet in flatten([
      for region_key, region in var.regions : [
        for subnet_key, subnet in try(region.vnet.subnets, {}) : {
          subnet_key        = "${region_key}-${subnet_key}"
          region_key        = region_key
          subnet_name       = try(subnet.name, subnet_key)
          address_prefixes  = subnet.address_prefixes
          service_endpoints = try(subnet.service_endpoints, null)
          delegations       = try(subnet.delegations, {})
        }
      ]
    ]) : subnet.subnet_key => subnet
  }

  name                 = each.value.subnet_name
  resource_group_name  = azurerm_resource_group.this[each.value.region_key].name
  virtual_network_name = azurerm_virtual_network.this[each.value.region_key].name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints

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
  for_each = toset(flatten([
    for region_key, region in var.regions : [
      "privatelink.${region.location}.azmk8s.io",
      "privatelink.${region.location}.database.windows.net",
      "privatelink.${region.location}.blob.core.windows.net",
      "privatelink.vaultcore.azure.net"
    ]
  ]))

  name                = each.key
  resource_group_name = azurerm_resource_group.this["primary"].name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = {
    for link in flatten([
      for region_key, region in var.regions : [
        for dns_zone in [
          "privatelink.${region.location}.azmk8s.io",
          "privatelink.${region.location}.database.windows.net",
          "privatelink.${region.location}.blob.core.windows.net",
          "privatelink.vaultcore.azure.net"
          ] : {
          name          = "${dns_zone}-${region_key}"
          region_key    = region_key
          dns_zone_name = dns_zone
        }
      ]
    ]) : link.name => link
  }

  name                  = each.value.name
  resource_group_name   = azurerm_resource_group.this["primary"].name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.value.dns_zone_name].name
  virtual_network_id    = azurerm_virtual_network.this[each.value.region_key].id
  registration_enabled  = false
}
