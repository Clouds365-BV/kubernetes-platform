resource "azurerm_public_ip" "agw" {
  for_each = var.regions

  name                = "${local.resource_name_prefix}-${each.key}-agw-pip"
  resource_group_name = azurerm_resource_group.this[each.key].name
  location            = azurerm_resource_group.this[each.key].location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.tags
}

resource "azurerm_user_assigned_identity" "agic" {
  for_each = var.regions

  name                = "${local.resource_name_prefix}-${each.key}-agic-id"
  resource_group_name = azurerm_resource_group.this[each.key].name
  location            = azurerm_resource_group.this[each.key].location

  tags = local.tags
}

module "agw-roles" {
  source = "../../modules/azure/authorization/role-assignment"
  for_each = {
    "Key Vault Secrets User" : azurerm_key_vault.this.id
  }

  object_id            = azurerm_user_assigned_identity.agw.principal_id
  role_definition_name = each.key
  resource_id          = each.value
}

resource "azurerm_application_gateway" "this" {
  for_each = var.regions

  name                = "${local.resource_name_prefix}-${each.key}-agw"
  resource_group_name = azurerm_resource_group.this[each.key].name
  location            = azurerm_resource_group.this[each.key].location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  waf_configuration {
    enabled                  = true
    firewall_mode            = "Prevention"
    rule_set_type            = "OWASP"
    rule_set_version         = "3.2"
    file_upload_limit_mb     = 100
    request_body_check       = true
    max_request_body_size_kb = 128
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = azurerm_subnet.this["${each.key}-agw"].id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_port {
    name = "https"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.agw[each.key].id
  }

  backend_address_pool {
    name  = "dummy"
    fqdns = ["ghost.example.com"]
  }

  backend_http_settings {
    name                  = "dummy"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "dummy"
    frontend_ip_configuration_name = "frontend-ip-configuration"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "dummy"
    rule_type                  = "Basic"
    http_listener_name         = "dummy"
    backend_address_pool_name  = "dummy"
    backend_http_settings_name = "dummy"
    priority                   = 100
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.agic[each.key].id
    ]
  }

  tags = local.tags
}

# Contributor role for AGIC identity on the Application Gateway
resource "azurerm_role_assignment" "agic_contributor" {
  for_each = var.regions

  scope                = azurerm_application_gateway.this[each.key].id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.agic[each.key].principal_id
}

# Reader role for AGIC identity on the Resource Group
resource "azurerm_role_assignment" "agic_reader" {
  for_each = var.regions

  scope                = azurerm_resource_group.this[each.key].id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.agic[each.key].principal_id
}
