resource "azurerm_resource_group" "this" {
  for_each = var.regions

  name     = "${local.resource_name_prefix}-${each.key}-rg"
  location = each.value.location

  tags = local.tags
}

resource "azurerm_log_analytics_workspace" "this" {
  for_each = var.regions

  name                = "${local.resource_name_prefix}-${each.key}-la"
  location            = azurerm_resource_group.this[each.key].location
  resource_group_name = azurerm_resource_group.this[each.key].name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.tags
}

resource "azurerm_log_analytics_solution" "container_insights" {
  for_each = var.regions

  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.this[each.key].location
  resource_group_name   = azurerm_resource_group.this[each.key].name
  workspace_resource_id = azurerm_log_analytics_workspace.this[each.key].id
  workspace_name        = azurerm_log_analytics_workspace.this[each.key].name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

# Front Door for multi-region traffic management and disaster recovery
resource "azurerm_frontdoor" "this" {
  name                = "${local.resource_name_prefix}-frontdoor"
  resource_group_name = azurerm_resource_group.this["primary"].name

  routing_rule {
    name               = "ghost-blog-rule"
    accepted_protocols = ["Http", "Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["ghost-blog-frontend"]

    forwarding_configuration {
      forwarding_protocol = "HttpsOnly"
      backend_pool_name   = "ghost-blog-backend"
    }
  }

  backend_pool {
    name = "ghost-blog-backend"

    dynamic "backend" {
      for_each = var.regions

      content {
        host_header = "${local.resource_name_prefix}-${backend.key}-agw.azurefd.net"
        address     = "${local.resource_name_prefix}-${backend.key}-agw.azurefd.net"
        http_port   = 80
        https_port  = 443
        weight      = backend.key == "primary" ? 100 : 1
        enabled     = true
      }
    }

    load_balancing_name = "ghost-blog-lb"
    health_probe_name   = "ghost-blog-hp"
  }

  backend_pool_load_balancing {
    name = "ghost-blog-lb"
  }

  backend_pool_health_probe {
    name                = "ghost-blog-hp"
    protocol            = "Https"
    path                = "/"
    interval_in_seconds = 30
  }

  frontend_endpoint {
    name                         = "ghost-blog-frontend"
    host_name                    = "${local.resource_name_prefix}-frontdoor.azurefd.net"
    session_affinity_enabled     = true
    session_affinity_ttl_seconds = 300

    web_application_firewall_policy_link_id = azurerm_frontdoor_firewall_policy.waf_policy.id
  }

  tags = local.tags
}

# WAF Policy for Front Door
resource "azurerm_frontdoor_firewall_policy" "waf_policy" {
  name                = "${local.resource_name_prefix}-waf-policy"
  resource_group_name = azurerm_resource_group.this["primary"].name
  enabled             = true
  mode                = "Prevention"

  managed_rule {
    type    = "DefaultRuleSet"
    version = "1.0"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
  }

  tags = local.tags
}
