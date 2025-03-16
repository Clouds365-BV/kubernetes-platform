resource "azurerm_role_assignment" "k8s" {
  scope                = azurerm_subnet.this["app_gateway"].id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.ingress_application_gateway.ingress_application_gateway_identity
}
