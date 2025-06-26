module "k8s-agic-roles" {
  source = "../../modules/azure/authorization/role-assignment"
  # roles below separated, because it can be multiple resources with same role name
  for_each = {
    "subnet|Network Contributor" : azurerm_subnet.this["app_gateway"].id,
    "resource_group|Reader" : azurerm_resource_group.this["primary"].id,
    "application_gateway|Contributor" : azurerm_application_gateway.this["primary"].id,
    "user_assigned_identity|Contributor" : azurerm_user_assigned_identity.k8s["primary"].id
  }

  object_id            = azurerm_kubernetes_cluster.this["primary"].ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  role_definition_name = split("|", each.key)[1]
  resource_id          = each.value
}
