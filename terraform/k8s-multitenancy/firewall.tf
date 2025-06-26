resource "azurerm_public_ip" "firewall" {
  for_each = var.regions

  name                = "${local.resource_name_prefix}-${each.key}-fw-pip"
  location            = azurerm_resource_group.this[each.key].location
  resource_group_name = azurerm_resource_group.this[each.key].name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.tags
}

resource "azurerm_firewall" "this" {
  for_each = var.regions

  name                = "${local.resource_name_prefix}-${each.key}-fw"
  location            = azurerm_resource_group.this[each.key].location
  resource_group_name = azurerm_resource_group.this[each.key].name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Premium"
  firewall_policy_id  = azurerm_firewall_policy.this[each.key].id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.this["${each.key}-AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.firewall[each.key].id
  }

  tags = local.tags
}

resource "azurerm_firewall_policy" "this" {
  for_each = var.regions

  name                = "${local.resource_name_prefix}-${each.key}-fwpolicy"
  resource_group_name = azurerm_resource_group.this[each.key].name
  location            = azurerm_resource_group.this[each.key].location
  sku                 = "Premium"

  dns {
    proxy_enabled = true
  }

  threat_intelligence_mode = "Deny"

  intrusion_detection {
    mode = "Alert"
  }

  tags = local.tags
}

# Network rules for firewall
resource "azurerm_firewall_policy_rule_collection_group" "network_rules" {
  for_each = var.regions

  name               = "network-rules"
  firewall_policy_id = azurerm_firewall_policy.this[each.key].id
  priority           = 100

  network_rule_collection {
    name     = "network-rules"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "allow-dns"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["168.63.129.16"]
      destination_ports     = ["53"]
    }

    rule {
      name                  = "allow-azureservices"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["AzureCloud"]
      destination_ports     = ["443"]
    }
  }
}

# Application rules for firewall
resource "azurerm_firewall_policy_rule_collection_group" "app_rules" {
  for_each = var.regions

  name               = "app-rules"
  firewall_policy_id = azurerm_firewall_policy.this[each.key].id
  priority           = 200

  application_rule_collection {
    name     = "app-rules"
    priority = 100
    action   = "Allow"

    rule {
      name = "allow-dockerhub"

      source_addresses = ["*"]

      destination_fqdn_tags = ["DockerHub"]

      protocols {
        port = "443"
        type = "Https"
      }
    }

    rule {
      name = "allow-microsoft-services"

      source_addresses = ["*"]

      destination_fqdns = [
        "*.microsoft.com",
        "*.windowsupdate.com",
        "*.visualstudio.com",
        "*.azure.com",
        "*.azure-automation.net",
        "*.azureedge.net"
      ]

      protocols {
        port = "443"
        type = "Https"
      }
    }
  }
}

# Route tables for forcing traffic through firewall
resource "azurerm_route_table" "this" {
  for_each = var.regions

  name                = "${local.resource_name_prefix}-${each.key}-rt"
  location            = azurerm_resource_group.this[each.key].location
  resource_group_name = azurerm_resource_group.this[each.key].name

  route {
    name                   = "to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.this[each.key].ip_configuration[0].private_ip_address
  }

  tags = local.tags
}

resource "azurerm_subnet_route_table_association" "k8s" {
  for_each = var.regions

  subnet_id      = azurerm_subnet.this["${each.key}-k8s"].id
  route_table_id = azurerm_route_table.this[each.key].id
}
