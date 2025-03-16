resource "azurerm_role_assignment" "k8s-agic" {
  scope                = azurerm_subnet.this["app_gateway"].id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.ingress_application_gateway[0].ingress_application_gateway_identity[0].principal_id
}
