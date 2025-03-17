module "k8s-agic-roles" {
  source = "../modules/azure/authorization/role-assignment"
  for_each = {
    "Network Contributor" : azurerm_subnet.this["app_gateway"].id,
    "Reader" : azurerm_resource_group.this.id,
    "Contributor" : azurerm_application_gateway.this.id
  }

  object_id = azurerm_kubernetes_cluster.this.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  #client_id
  role_definition_name = each.key
  resource_id          = each.value
}
