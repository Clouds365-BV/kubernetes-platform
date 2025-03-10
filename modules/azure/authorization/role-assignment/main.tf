resource "azurerm_role_assignment" "this" {
  scope                = var.resource_id
  role_definition_name = var.role_definition_name
  principal_id         = local.role_assignment_id
}
