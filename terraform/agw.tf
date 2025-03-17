resource "azurerm_user_assigned_identity" "agw" {
  name                = "${local.resource_name_prefix}-agw-id"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  tags = local.tags
}

module "agw-roles" {
  source = "../modules/azure/authorization/role-assignment"
  for_each = {
    "Key Vault Secrets User" : azurerm_key_vault.this.id
  }

  object_id            = azurerm_user_assigned_identity.agw.principal_id
  role_definition_name = each.key
  resource_id          = each.value
}

resource "azurerm_application_gateway" "this" {
  name                = "${local.resource_name_prefix}-agw"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  ssl_policy {
    disabled_protocols = ["TLSv1_0", "TLSv1_1"]
  }

  gateway_ip_configuration {
    name      = "AppGatewayIpConfig"
    subnet_id = azurerm_subnet.this["app_gateway"].id
  }

  ssl_certificate {
    name                = "drones-shuttles"
    key_vault_secret_id = azurerm_key_vault_certificate.drones_shuttles.secret_id
  }

  frontend_port {
    name = "HttpPort"
    port = 80
  }

  frontend_port {
    name = "HttpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "AppGatewayFrontendIp"
    public_ip_address_id = azurerm_public_ip.this["app_gateway"].id
  }

  backend_address_pool {
    name = "AksBackendPool"
  }

  backend_http_settings {
    name                  = "AksBackendHttpSettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "HttpListener"
    frontend_ip_configuration_name = "AppGatewayFrontendIp"
    frontend_port_name             = "HttpPort"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "HttpRoutingRule"
    http_listener_name         = "HttpListener"
    backend_address_pool_name  = "AksBackendPool"
    backend_http_settings_name = "AksBackendHttpSettings"
    rule_type                  = "Basic"
    priority                   = 10
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.agw.id
    ]
  }

  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      http_listener,
      probe,
      request_routing_rule,
      tags["ingress-for-aks-cluster-id"],
      tags["managed-by-k8s-ingress"],
    ]
  }

  depends_on = [
    module.agw-roles
  ]

  tags = local.tags
}
