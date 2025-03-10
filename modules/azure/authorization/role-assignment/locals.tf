locals {
  object_id = var.object_id == null ? null : [{ id = var.object_id }]
  role_assignment_object = coalescelist(
    data.azuread_group.this,
    data.azuread_service_principal.this,
    data.azuread_user.this,
    local.object_id
  )
  role_assignment_id = local.role_assignment_object[0].id
}
