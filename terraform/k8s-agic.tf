module "k8s-agic-roles" {
  source = "../modules/azure/authorization/role-assignment"
  for_each = {
    "subnet|Network Contributor" : azurerm_subnet.this["app_gateway"].id,
    "resource_group|Reader" : azurerm_resource_group.this.id,
    "application_gateway|Contributor" : azurerm_application_gateway.this.id,
    "user_assigned_identity|Contributor" : azurerm_user_assigned_identity.agw.id
  }

  object_id            = azurerm_kubernetes_cluster.this.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  role_definition_name = split("|", each.key)[2]
  resource_id          = each.value
}
