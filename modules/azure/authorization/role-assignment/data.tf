data "azuread_group" "this" {
  count        = var.ad_group_name == null ? 0 : 1
  display_name = var.ad_group_name
}

data "azuread_service_principal" "this" {
  count        = var.service_principal_name == null ? 0 : 1
  display_name = var.service_principal_name
}

data "azuread_user" "this" {
  count               = var.email_id == null ? 0 : 1
  user_principal_name = var.email_id
}
