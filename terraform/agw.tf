resource "azurerm_application_gateway" "this" {
  name                = "${local.resource_name_prefix}-agw"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "AppGatewayIpConfig"
    subnet_id = azurerm_subnet.this["AppGateway"].id
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
    public_ip_address_id = azurerm_public_ip.this["AppGateway"].id
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
  }
}
