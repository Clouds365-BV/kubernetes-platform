locals {
  agic_roles = {
    "Network Contributor" : azurerm_subnet.this["app_gateway"].id,
    "Reader" : azurerm_resource_group.this.id,
    "Contributor" : azurerm_application_gateway.this.id
  }
}

resource "azurerm_role_assignment" "k8s-agic" {
  for_each = local.agic_roles

  scope                = each.value
  role_definition_name = each.key
  principal_id         = azurerm_kubernetes_cluster.this.ingress_application_gateway[0].ingress_application_gateway_identity[0].client_id
}
