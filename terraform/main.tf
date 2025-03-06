resource "azurerm_resource_group" "this" {
  name     = "${local.resource_name_prefix}-rg"
  location = var.location

  tags = local.tags
}

# resource "azurerm_user_assigned_identity" "this" {
#   for_each = try(var.env.identity, {})
#
#   name                = try(each.value.name, "${local.resource_name_prefix}-${each.key}-id")
#   location            = azurerm_resource_group.this.location
#   resource_group_name = azurerm_resource_group.this.name
#
#   tags = local.tags
# }
#
# module "role_assignment_container_registry" {
#   source = "../../modules/azure/authorization/role-assignment"
#   for_each = {
#     for k, v in try(var.env.identity, {}) : k => v
#     if try(v.container_registry, false) != false
#   }
#
#   object_id            = azurerm_user_assigned_identity.this[each.key].principal_id
#   role_definition_name = each.value.container_registry.role
#   resource_id          = data.azurerm_container_registry.this[each.value.container_registry.name].id
# }
#
# resource "azurerm_log_analytics_workspace" "this" {
#   for_each = try(var.env.log_analytics_workspace, {})
#
#   name                = try(each.value.name, "${local.resource_name_prefix}-${each.key}-log")
#   location            = azurerm_resource_group.this.location
#   resource_group_name = azurerm_resource_group.this.name
#   sku                 = each.value.sku_name
#   retention_in_days   = each.value.retention_in_days
#
#   tags = local.tags
# }
#
# module "application_insights" {
#   source   = "../../modules/azure/application-insights"
#   for_each = try(var.env.application_insights, {})
#
#   name                       = try(each.value.name, "${local.resource_name_prefix}-${each.key}-appi")
#   location                   = try(each.value.location, azurerm_resource_group.this.location)
#   resource_group_name        = azurerm_resource_group.this.name
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.this[each.value.log_analytics_workspace].id
#   application_type           = each.value.application_type
#
#   tags = local.tags
# }
#
# resource "azurerm_storage_account" "this" {
#   name                     = replace(replace("${local.resource_name_prefix}-st", "-", ""), "_", "")
#   location                 = azurerm_resource_group.this.location
#   resource_group_name      = azurerm_resource_group.this.name
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#
#   tags = local.tags
# }
#
# module "postgresql" {
#   source   = "../../modules/azure/database/postgresql"
#   for_each = try(var.env.databases.postgresql, {})
#
#   name                   = try(each.value.name, "${local.resource_name_prefix}-${each.key}-psql")
#   location               = try(each.value.location, azurerm_resource_group.this.location)
#   resource_group_name    = azurerm_resource_group.this.name
#   administrator_login    = strcontains(each.value.administrator_login, "|") ? module.key_vault_secret[each.value.administrator_login].value : each.value.administrator_login
#   administrator_password = strcontains(each.value.administrator_password, "|") ? module.key_vault_secret[each.value.administrator_password].value : each.value.administrator_password
#   sku_name               = each.value.sku_name
#   config = merge(
#     each.value,
#     {
#       delegated_subnet_id        = try(strcontains(each.value.delegated_subnet_id, "|") ? data.azurerm_subnet.this[each.value.delegated_subnet_id].id : each.value.delegated_subnet_id, null)
#       private_endpoint_subnet_id = try(strcontains(each.value.private_endpoint_subnet_id, "|") ? data.azurerm_subnet.this[each.value.private_endpoint_subnet_id].id : each.value.private_endpoint_subnet_id, null)
#       private_dns_zone_ids       = [for pdz in try(each.value.private_dns_zones, []) : module.private_dns_zone[pdz].id]
#       log_analytics_workspace_id = try(azurerm_log_analytics_workspace.this[each.value.log_analytics_workspace_id].id, null)
#     }
#   )
#   tags = local.tags
#
#   depends_on = [
#     data.azurerm_subnet.this,
#     module.key_vault_secret,
#     module.private_dns_zone
#   ]
# }
#
# module "cognitive_service" {
#   source   = "../../modules/azure/cognitive-service"
#   for_each = try(var.env.cognitive_service, {})
#
#   name                = try(each.value.name, "${local.resource_name_prefix}-${each.key}-oai")
#   location            = try(each.value.location, azurerm_resource_group.this.location)
#   resource_group_name = azurerm_resource_group.this.name
#   kind                = each.value.kind
#   sku_name            = each.value.sku_name
#   config = merge(
#     each.value,
#     {
#       private_endpoint_subnet_id = try(strcontains(each.value.private_endpoint_subnet_id, "|") ?
#       data.azurerm_subnet.this[each.value.private_endpoint_subnet_id].id : each.value.private_endpoint_subnet_id, null)
#       private_dns_zone_ids       = [for pdz in try(each.value.private_dns_zones, []) : module.private_dns_zone[pdz].id]
#       log_analytics_workspace_id = try(azurerm_log_analytics_workspace.this[each.value.log_analytics_workspace_id].id, null)
#     }
#   )
#
#   tags = local.tags
# }